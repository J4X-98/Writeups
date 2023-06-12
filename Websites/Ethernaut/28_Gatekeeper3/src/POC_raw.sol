// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/Chal.sol";
import "../src/Attack.sol";

contract Hack is Test {
    GatekeeperThree gate_keeper;

    address bigBoss = makeAddr("bigBoss");
    address hacker = makeAddr("hacker");

    function setUp() public {
        //Deal some money to everyone
        vm.deal(bigBoss, 1 ether);
        vm.deal(hacker, 1 ether);

        vm.startPrank(bigBoss);
        //Deploy the gatekeeper contract
        gate_keeper = new GatekeeperThree();
        vm.stopPrank();
    }

    function test_attack() public {
        vm.startPrank(hacker);
        //SOLUTION START



        //SOLUTION END
        vm.stopPrank();

        //Check if entrant is you
        assertEq(gate_keeper.entrant(), address(hacker));
    }
}