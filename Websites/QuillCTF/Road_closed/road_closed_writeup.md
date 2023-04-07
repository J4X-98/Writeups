# Road Closed

## Challenge

We get one contract which we need to exploit

```
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

contract RoadClosed {

    bool hacked;
    address owner;
		address pwner;
    mapping(address => bool) whitelistedMinters;


    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
            }
        return size > 0;
    }

    function isOwner() public view returns(bool){
        if (msg.sender==owner) {
            return true;
        }
        else return false;
    }

    constructor() {
        owner = msg.sender;
    }

    function addToWhitelist(address addr) public {
        require(!isContract(addr),"Contracts are not allowed");
        whitelistedMinters[addr] = true;
    }
    

    function changeOwner(address addr) public {
        require(whitelistedMinters[addr], "You are not whitelisted");
				require(msg.sender == addr, "address must be msg.sender");
        require(addr != address(0), "Zero address");
        owner = addr;
    }

    function pwn(address addr) external payable{
        require(!isContract(msg.sender), "Contracts are not allowed");
				require(msg.sender == addr, "address must be msg.sender");
        require (msg.sender == owner, "Must be owner");
        hacked = true;
    }

    function pwn() external payable {
        require(msg.sender == pwner);
        hacked = true;
    }

    function isHacked() public view returns(bool) {
        return hacked;
    }
}
```

The goal is to become the owner and overwrite the hacked variable to be true.

## Solution

This contract is very easiyl solved, i guess it's just a poc.

1. Call addToWhitelist with your own address as a param, as this only checks if you are a contract, you can just do this directly using your account in remix
2. Call changeOwner with your own address as the parameter. This functions requires that you are whitelisted, that the address you send is the msg.sender address and it's not a 0 address, which we all fulfill if we again send using remix
3. Now that you are the owner you can just call pwn() and the challenge is solved.