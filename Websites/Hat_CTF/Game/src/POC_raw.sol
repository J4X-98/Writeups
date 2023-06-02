// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/Game.sol";
import "../src/Attacker.sol";

contract Hack is Test {
    Game game;

    address bigBoss = makeAddr("bigBoss");
    address hacker = makeAddr("hacker");
    address hacker2 = makeAddr("hacker2");
    uint blockGasLimit = 120000;

    function setUp() public {
        //Deal some money to everyone
        vm.deal(bigBoss, 1 ether);
        vm.deal(hacker, 1 ether);

        vm.startPrank(bigBoss);
        //Deploy the game contract
        game = new Game();
        vm.stopPrank();
    }

    function test_attack() public {
        vm.startPrank(hacker);

        //SOLUTION here

        vm.stopPrank();

        //Check if flagHolder is your contract
        assertEq(game.flagHolder(), 0); //Add your address 
    }
}