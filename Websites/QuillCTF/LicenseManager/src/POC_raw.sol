// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/LicenseManager.sol";

/** 
 * @title Test contract for LicenseManager
 */
contract LicenseManagerTest is Test {

    LicenseManager license;

    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");

    address attacker = makeAddr("attacker");
    
    function setUp() public {
        vm.prank(owner);
        license = new LicenseManager();

        vm.deal(user1, 1 ether);
        vm.deal(user2, 1 ether);
        vm.deal(user3, 1 ether);
        vm.deal(user4, 1 ether);

        vm.prank(user1);
        license.buyLicense{value: 1 ether}();

        vm.prank(user2);
        license.buyLicense{value: 1 ether}();

        vm.prank(user3);
        license.buyLicense{value: 1 ether}();

        vm.prank(user4);
        license.buyLicense{value: 1 ether}();

    }


    function test_exploit1_2() public {
        vm.deal(attacker, 0.01 ether);
        vm.startPrank(attacker);
        //Challenge 1 solution
        assertEq(true, license.checkLicense());
        vm.stopPrank();
						
        vm.startPrank(attacker);
        //Challenge 2.1 solution
        assertGt(attacker.balance, 0.1 ether);
        vm.stopPrank();

    }
		/// collect the ethers in the contract before the owner notices in second way.
    function test_exploit3() public {
        vm.deal(address(this), 1 ether);
				// challenge 2.2 solution
				console.log("\tFinal Balance\t", address(this).balance);
        assertGt(address(this).balance, 1 ether);
    }
}