// Description:
// A forge testcase which you cam use to easily debug challenges that were built using the Paradigm CTF framework.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/Test.sol";
import "../src/Pigeon.sol";
import "../src/Attack.sol";
//Import all needed contracts here (they are usually stored in /src in your foundry directory)

contract ParadigmTest is Test {
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");
    //Initialize any additional needed variables here
    Pigeon public pigeon;

    function setUp() public {
        vm.deal(deployer, 1337 ether);
        vm.startPrank(deployer);

        //Copy all code from the Setup.sol constructor() function into here
        pigeon = new Pigeon();

        // Junior Pigeons
        pigeon.assignPigeon("Numbuh", "6", address(0x006), 0);
        pigeon.assignPigeon{value: 5e18}("Numbuh", "5", address(0x005), 0);

        pigeon.assignPigeon("Numbuh", "4", address(0x004), 1);
        pigeon.assignPigeon{value: 10e18}("Numbuh", "3", address(0x003), 1);

        pigeon.assignPigeon("Numbuh", "2", address(0x002), 2);
        pigeon.assignPigeon{value: 15e18}("Numbuh", "1", address(0x001), 2);

        vm.stopPrank();
    }

    function test() public {
        vm.deal(attacker, 5 ether); //30 eth are the standard for the paradigm framework, but could be configured differently
        vm.startPrank(attacker);

        //Code your solution here
        Attack atk = new Attack(address(pigeon));

        atk.attack();

        vm.stopPrank();
        
        assertEq(isSolved(), true);
    }

    function isSolved() public view returns (bool) {
        //Copy the content of the isSolved() function from the Setup.sol contract here (maybe needs adaption is it includes msg.sender, then just change it to the attacker variable)
        return attacker.balance >= 34 ether && address(pigeon).balance == 0 ether;
        return false;
    }
}