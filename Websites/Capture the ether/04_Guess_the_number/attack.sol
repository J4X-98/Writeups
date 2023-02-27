// SPDX-License-Identifier: MIT
pragma solidity ^0.4.21;

import "./target.sol";

contract attack
{
    GuessTheNumberChallenge target;
    
    constructor(address target_addr) payable
    {
        require(msg.value == 1 ether);
        target = GuessTheNumberChallenge(target_addr);
    }

    function attack_fun() public
    {
        target.guess{value: 1 ether}(42);
    }
}