// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WETH10.sol";

contract Returner
{
    address owner;
    WETH10 target;

    constructor(address payable _target)
    {
        owner = msg.sender;
        target = WETH10(_target);
    }

    function returnTokens() public
    {
        target.transfer(owner, target.balanceOf(address(this)));
    }
}