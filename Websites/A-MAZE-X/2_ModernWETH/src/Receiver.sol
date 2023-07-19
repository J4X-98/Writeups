// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ModernWETH.sol";
import "./Receiver.sol";

contract Receiver
{
    ModernWETH public weth;
    address public attacker;

    constructor(address _wethAddress) {
        weth = ModernWETH(_wethAddress);
        attacker = msg.sender;
    }

    function giveMyMoneysBack() public {
        weth.transfer(attacker, weth.balanceOf(address(this)));
    }
}