// Description:
// A forge testcase which you can use to easily debug challenges that were built using the Paradigm CTF framework.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/Test.sol";
//Import all needed contracts here (they are usually stored in /src in your foundry directory)
import "../src/PETH.sol";
import "../src/PigeonBank.sol";
import "../src/Attacker.sol";

contract ParadigmTest is Test {
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    //Initialize any additional needed variables here
    PigeonBank pigeonBank;
    PETH peth;

    function setUp() public {
	    vm.deal(deployer, 2500 ether);
        vm.startPrank(deployer);

        //Copy all code from the Setup.sol constructor() function into here
        pigeonBank = new PigeonBank();
        peth = pigeonBank.peth();

        // @dev - Deposit 2500 ETH to PigeonBank
        pigeonBank.deposit{value: 2500 ether}();

        vm.stopPrank();
    }

    function test() public {
        //30 eth are the standard for the paradigm framework, but this could be configured differently, you can easily check this by importing the rpc url and private key into metamask and checking the balance of the deployer account
        vm.deal(attacker, 10 ether); 
        vm.startPrank(attacker);

        //Code your solution here
        Attacker attackerContract = new Attacker(address(pigeonBank));
        attackerContract.attack{value: 10 ether}();

        vm.stopPrank();
        assertEq(isSolved(), true);
    }

    function isSolved() public view returns (bool) {
        //Copy the content of the isSolved() function from the Setup.sol contract here
        return (peth.totalSupply() == 0) && (address(attacker).balance >= 2500 ether);
    }
}