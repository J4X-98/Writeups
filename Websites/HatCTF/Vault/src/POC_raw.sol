// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/Vault.sol";
import "../src/ERC4626.sol";

contract Hack is Test {
    Vault vault;

    address bigBoss = makeAddr("bigBoss");
    address hacker = makeAddr("hacker");

    function setUp() public {
        //Deal some money to everyone
        vm.deal(bigBoss, 1 ether);
        vm.deal(hacker, 1 ether);

        vm.startPrank(bigBoss);
        //Deploy the vault contract
        vault = new Vault();
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