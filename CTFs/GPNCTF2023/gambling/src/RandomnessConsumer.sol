// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./RandomnessDealer.sol";

abstract contract RandomnessConsumer {
    RandomnessDealer public randomDealer;

    function acceptRandomness(uint _number) internal virtual;

    function acceptRandomnessWrapper(uint _number) isRandomDealer external {
        acceptRandomness(_number);
    }

    modifier isRandomDealer () {
        require(address(randomDealer) != address(0), "Contract not initialized");
        require(address(randomDealer) == msg.sender, "Not random dealer");
        _;
    }
}
