# Donate

## Challenge

We are provided a contract:

```
// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract Donate {
    event t1(bytes _sig);
    address payable public keeper;
    address public owner;
    event newDonate(address indexed, uint amount);

    modifier onlyOwner() {
        require(
            msg.sender == owner || msg.sender == address(this),
            "You are not Owner"
        );
        _;
    }

    constructor(address _keeper) {
        keeper = payable(_keeper);
        owner = msg.sender;
    }

    function pay() external payable {
        keeper.transfer(msg.value);
        emit newDonate(msg.sender, msg.value);
    }

    function changeKeeper(address _newKeeper) external onlyOwner {
        keeper = payable(_newKeeper);
    }

    function secretFunction(string memory f) external {
        require(
            keccak256(bytes(f)) !=
                0x097798381ee91bee7e3420f37298fe723a9eedeade5440d4b2b5ca3192da2428,
            "invalid"
        );
        (bool success, ) = address(this).call(
            abi.encodeWithSignature(f, msg.sender)
        );
        require(success, "call fail");
    }

    function keeperCheck() external view returns (bool) {
        return (msg.sender == keeper);
    }
}
```

In addition we also get a basic foundry setup to build the poc upon.

Our goal is to call the keeperCheck function and receive true as a return value.

## Solution

The interesting part here is the secretfunction which calls the function we give it, if it's hash doesn't match the given hash. As i am a lazy person i just threw the signature of the changeKeeper function ("changeKeeper(address)") into cyberchef and generated the keccak 256, which , what a coincidence, seems to match. So we know that we cann pass everything but this functions string to the secretFunction and it should pass. 

But our goal is to still call the function changeKeeper. The way how we can exploit this is by abusing a "feature" of solidity. To encode a functions signature it only uses the first 4 bytes of the hash. So if we have another function signature that's hash starts in the same 4 bytes, we can abuse this to pass the hash check, but still get our function to be called in the end. I used the database of solidity signatures https://www.4byte.directory/signatures/?bytes4_signature=0x09779838 to look up the hash and found 2 colliding functions. I just used the first one ("refundETHAll(address)") and it worked.

