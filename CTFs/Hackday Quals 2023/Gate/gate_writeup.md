# Gate - Web3

## The Challenge

The challenge is centered around a contract called gate. The goal is to be able to pass the letMeIn function without reverting.

```
contract Gate {
    address public idManager;
    uint8[] private password;
    bool public gateLocked = true;

    constructor(address _idManager, uint8[] memory _password) {
        idManager = _idManager;
        password = _password;
    }

    function letMeIn(string memory _password) public returns(string memory) {
        (bool success, bytes memory result) = idManager.call(abi.encodeWithSignature("getIdentity(address)", msg.sender));
        require(success);
        string memory name = abi.decode(result, (string));
        bytes memory passbytes = bytes(_password);

        // user must be registered with a name
        require(bytes(name).length > 0 && passbytes.length == password.length);

        // user must be privileged
        idManager.call(abi.encodeWithSignature("requirePrivileges(address)", msg.sender));
        
        // user must know our secret password
        for (uint256 i = 0; i < password.length; i++) {
            require(password[i] == uint8(passbytes[i]));
        }

        gateLocked = false;
        return string.concat("Welcome, ", name);
    }
}
```

There also is an additional contract for the identity manager which should check if you are registered and also priviledged.

```
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

// The following contract is vulnerable on purpose: DO NOT COPY AND USE IT ON MAINNET!
contract IdentityManager {
    mapping(address => string) private identities;
    mapping(address => bool) private privileged;

    constructor() {
        privileged[msg.sender] = true;
    }

    function setMyIdentity(string memory name) public {
        identities[msg.sender] = name;
    }

    function setIdentityFor(address addr, string memory name) public {
        requirePrivileges(msg.sender);
        identities[addr] = name;
    }

    function setPrivileged(address addr) public {
        requirePrivileges(msg.sender);
        privileged[addr] = true;
    }

    function requirePrivileges(address addr) public view {
        require(privileged[addr]);
    }

    function getIdentity(address id) public view returns(string memory) {
        return identities[id];
    }
}

```

## Solution

There are 3 challenges that we need to pass to be able to go through the whole function. 
- Be registered
- Be priviledged
- Pass the right password


### 1. Register

This can be done super easily by just calling the setMyIdentity() function of the identity manager. The address of the IdentityManager can be retrieved from the gate contract. 


### 2. Privilege

This one can also be passed without any issues, because the gate contract doesn't check if the function requirePrivileges() fails.


### 3. Password

This is the only part of the chall that requires some skill. The password is set to private, but as we all know everything on the blockchain is public. Your contract can't directly access it, but it can be retrieved using the web3.js library. I have added a example script below.


```
// Import the web3.js library
const Web3 = require('web3');

// Set up the web3 provider using the RPC URL and chain ID of the custom blockchain
const web3 = new Web3(new Web3.providers.HttpProvider('http://sie2op7ohko.hackday.fr:8545'));
const chainId = 23;

// Get the storage value at a specific address and position
async function getStorageAt(address, position) {
  try {
    const storageValue = await web3.eth.getStorageAt(address, position);
    console.log(`Storage value at address ${address} and position ${position}: ${storageValue}`);
  } catch (error) {
    console.error(error);
  }
}

// Call the getStorageAt function with a specific address and position
getStorageAt('0xD8c60B0cDa79F0B8a433640529686eb8Be6a97a3', web3.utils.soliditySha3(1));
```

Now you have the password in hey, now you just need to transform it to ascii and call the function using it. The password should be "sh1ny st4rdu5t 1n th3 n1ght sk1es"
 
Now you can check the contract and get the flag.
