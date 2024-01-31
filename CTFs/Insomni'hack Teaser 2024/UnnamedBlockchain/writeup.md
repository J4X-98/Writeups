# Challenge

The Unnamed Web3 challenge is based around a smart contract as well as a flask webapp. The webapp offers DNS resolution, with the smart contract being used to store the domains, ips and owners.

## The WebApp

The webapp can be used to call the functions of the smart contract easily. It offers interaces to register a domain, initiating a domain transfer and transfering a domain. Additionally the app gives you a domain to which it will send the flag on request. As all domains that you can register end in ".inso", and the flag domain ends in ".flag" you can never register it the intended way.

## The Smart Contract

The smart contract is the backbone of the application and stores the data on the domains. It has public functions which allow users to register domains, initiate transfers, handle the transfers and change the ip of a domain.

# Analysis

As the domain can't be registered the original way due to `registerInsoDomain()` appending ".inso" to any registered domain there must be a different way to get a hold of the domain.

```solidity
function registerInsoDomain(
    string memory domain,
    string memory ip
) public payable {
    require(msg.value == 1 ether, "Registration fee is 1 ETH");

    domain = string.concat(domain, ".inso");
    require(
        domains[domain].owner == address(0),
        "Domain already registered"
    );

    DomainDetails memory newDomain = DomainDetails({
        owner: msg.sender,
        ip: ip
    });

    domains[domain] = newDomain;

    emit DomainRegistered(domain, msg.sender, ip);
}
```

The only other way to become the owner of an ip is to call the `transferDomain()` function with valid transferCodes.

```solidity
function transferDomain(
    string memory domain,
    string memory ip,
    bytes memory transferCode
) public {
    if (!verify(domain, msg.sender, transferCode)) {
        revert("Invalid transfer code");
    }

    DomainDetails memory newDomain = DomainDetails({
        owner: msg.sender,
        ip: ip
    });

    domains[domain] = newDomain;

    emit DomainTransfered(domain, msg.sender, ip);
}
```

Unfortunately these transferCodes are checked in the `verify()` function which will check if they were signed by the `signer` address. These codes get generated in the flask app which on call to `/transfer-codes` will check if the event `TransferInitiated()` has been emitted by the smart-contract, and in this case will generate the transfercodes for the transferrable domain. When one checks the `initiateTransfer()` function, one can see that it can only be called for domains of which we are the owner.


```solidity
function initiateTransfer(
    string memory domain,
    address destination
) public {
    require(
        domains[domain].owner == msg.sender,
        "Transfer must be initiated by owner"
    );

    emit TransferInitiated(domain, destination);
}
```

Now the last part of the analysis is to find out how the signing process works. To see this we can look at the `verify()` function.

```solidity
function verify(
    string memory domain,
    address owner,
    bytes memory signature
) private view returns (bool) {
    domain = string(abi.encodePacked(domain, "."));

    uint8 partCount = 0;
    for (uint i = 0; i < bytes(domain).length; i++) {
        if (bytes(domain)[i] == ".") {
            partCount++;
            require(partCount <= 64, "too many dots");
        }
    }

    bytes32[] memory parts = new bytes32[](partCount);
    uint8 partIndex = 0;
    string memory part;
    for (uint i = 0; i < bytes(domain).length; i++) {
        if (bytes(domain)[i] == ".") {
            part = string(abi.encodePacked(part, partCount - partIndex));
            bytes32 tmp;
            assembly {
                tmp := mload(add(part, 32))
            }
            parts[partIndex] = tmp;
            partIndex++;
            part = "";
        } else {
            part = string(abi.encodePacked(part, bytes(domain)[i]));
        }
    }

    for (uint i = 0; i < partCount; i++) {
        bytes32 r;
        bytes32 s;
        uint8 v = uint8(signature[i * 65 + 64]);
        assembly {
            r := mload(add(signature, add(32, mul(i, 65))))
            s := mload(add(signature, add(64, mul(i, 65))))
        }
        bytes32 hash = keccak256(abi.encodePacked(parts[i], owner));
        require(ecrecover(hash, v, r, s) == signer, "Invalid signature");
    }

    return true;
}
```

While looking complex the behavior can be explained in simple terms.

1. The domain gets split into parts at the dots
2. The number of the part gets appended to the part
3. Each part gets signed by the signer


# Exploit

So after analyzing we have to find a way how to get control over the flag domain. The domain is structured as `randomString.insomnihack.flag`. While we can easily get signatures for the randomstring and insomnihakc parts by registering a domain called `randomString.insomnihack.inso` and then initiating a transfer of the domain, the flag part is more tricky. As the index of the part (which are ordered in reverse) gets appended to the part, we would need to get a signature for the string `flag1`.

To solve this problem we have to take a deeper look at how the splitting and signing process works. Especially how parts get added to the array of parts.

```solidity
if (bytes(domain)[i] == ".") {
    part = string(abi.encodePacked(part, partCount - partIndex));
    bytes32 tmp;
    assembly {
        tmp := mload(add(part, 32))
    }
    parts[partIndex] = tmp;
    partIndex++;
    part = "";
} else {
    part = string(abi.encodePacked(part, bytes(domain)[i]));
}
```

To see the issue here requires some minor assembly knowledge to see what the small assembly part does. The `mload` opcode will load the next 32 bytes from the provided pointer and store it in tmp. As a result of this everythign of  a part that is longer than 32 bytes will be omitted, including the appended index. So to circumvent the safety measure one can register a domain which will be `flag1[27 zeroes].inso`. In the next step the splitter will append the index so the part becomes `flag1[27 zeroes]2`. As the 2 is in the 33rd byte it will be lost and only `flag1[27 zeroes]` will be hashed. As keccak256 will pad everything to 32 bytes, the hash is the same as for the string `"flag1"` which will be padded with 27 zeroes by keccak.

After calling initiateTransfer and receiving transfercodes by calling `/transfer-codes` we can move on to the last part of the exploit. We can just reorder the transfer codes so that they fit the domain `randomString.insomnihack.inso` and transfer the domain to ourselfs. When we look at the `/send-flag` endpoint of the webapp, we cna see that it will forward the fflag via a post request to our user provided ip. So we can either directly change the ip in the transfer call or do it afterwards using the contracts `updateIp()` function. Now we have to jsut open up a listener on port 80 and receive the flag .