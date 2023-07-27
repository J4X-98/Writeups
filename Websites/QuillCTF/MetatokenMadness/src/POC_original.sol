// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/CurvePool.sol";
import "../src/CurveToken.sol";
import "../src/interfaces/ILendingPool.sol";
import "../src/MetaPoolToken.sol";
import "../src/interfaces/IERC3156.sol";
import "forge-std/console.sol";



contract Challenge is Test {
    ILendingPool public wethLendingPool;
    CurvePool public swapPoolEthWeth;
    CurveToken public lpToken;
    IWETH public weth;
    MetaPoolToken public metaToken;
    address hacker;
    address alice;
    address bob;

    function setUp() public {
        vm.createSelectFork("https://sepolia.gateway.tenderly.co");

        weth = IWETH(payable(0x1194A239875cD36C9B960FF2d3d8d0f800435290));
        wethLendingPool = ILendingPool(0x66Df966E887e73b2f46456e062213B0C0fB42037);
        assertEq(address(wethLendingPool.WETH()), address(weth));
        assertEq(address(wethLendingPool.WETH()), address(weth));
        lpToken = new CurveToken();
        swapPoolEthWeth = new CurvePool(
            msg.sender, 
            [
                0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
                address(weth)
            ],
            address(lpToken), 
            5,
            4000000,
            5000000000
        );
        lpToken.initialize(address(swapPoolEthWeth));
        metaToken = new MetaPoolToken(lpToken, swapPoolEthWeth);
        // deal(address(lpToken), address(metaToken), 10000 ether, true);

        hacker = makeAddr("hacker");
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        uint[2] memory amounts;// = [10 ether, 10 ether];
        amounts[0] = 10 ether;
        amounts[1] = 10 ether;

        deal(alice, 20 ether);
        vm.startPrank(alice);
        
        weth.deposit{value: 10 ether}();
        assertEq(weth.balanceOf(alice), 10 ether, "alice failed");
        weth.approve(address(swapPoolEthWeth), type(uint).max);
        swapPoolEthWeth.add_liquidity{value: 10 ether}(amounts, 0);
        lpToken.approve(address(metaToken), type(uint).max);
        metaToken.mint(lpToken.balanceOf(alice));
        assertGt(metaToken.balanceOf(alice),0);
        vm.stopPrank();

        // amounts = [20 ether, 20 ether];
        amounts[0] = 20 ether;
        amounts[1] = 20 ether;

        deal(bob, 40 ether);
        vm.startPrank(bob);
        
        weth.deposit{value: 20 ether}();
        assertEq(weth.balanceOf(bob), 20 ether, "bob failed");
        weth.approve(address(swapPoolEthWeth), type(uint).max);
        swapPoolEthWeth.add_liquidity{value: 20 ether}(amounts, 0);
        lpToken.approve(address(metaToken), type(uint).max);
        metaToken.mint(lpToken.balanceOf(bob));
        assertGt(metaToken.balanceOf(bob),0);
        vm.stopPrank();

        // Provide initial liquidity to lending pool (and lots of it!)
        deal(address(this), type(uint256).max - 70 ether);
        weth.deposit{value: address(this).balance}();
        weth.transfer(address(wethLendingPool), weth.balanceOf(address(this)));

        // Provide hacker with some ETH to start with
        deal(hacker, 10 ether);
    }

    function testHack() public {
        uint lendingPoolWethBalance = weth.balanceOf(address(wethLendingPool));
        
        vm.startPrank(hacker, hacker);

        //Your Solution        

        vm.stopPrank();

        assertLt(weth.balanceOf(address(wethLendingPool)), lendingPoolWethBalance, "Did not steal WETH from LendingPool");
        assertApproxEqAbs(lpToken.balanceOf(address(metaToken)), 0, 1e5, "Did not completely drain LP tokens from MetaPoolToken");
        assertApproxEqRel(address(hacker).balance / weth.balanceOf(address(wethLendingPool)), 200, 5, "Did not obtain approx. 200x as much ETH as the final WETH lending pool balance");
    }
}