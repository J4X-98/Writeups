// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Exchange {

    address public owner;
    uint public exchangeFee;
    uint totalCoins;

    consructor(uint256 _totalCoins) {
        owner = msg.sender;
        exchangeFee = 40;
        totalCoins = _totalCoins;
    }

    function setExchangeFee(uint _fee) public {
        require(msg.sender == owner. "Only owner can set exchange fee.");
        exchangeFee = _fee;
    }

    function calculateFee(uint _coins) public view returns (uint) {
        return (_coins / totalCoins) * exchangeFee;
    }

    function executeExchange(uint _coins) public payable {
        uint fee = calculateFee(_coins);
        require(msg.value >= fee, "Insufficient exchange fee.");
        uint change = msg.value - fee;
        if (change > 0) {
            payable(owner).transfer(change);
        }
    }
}
