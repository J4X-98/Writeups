// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../src/GoldNFT.sol";
import "../src/Attack.sol";

contract Hack is Test {
    GoldNFT nft;
    address owner = makeAddr("owner");
    address hacker = makeAddr("hacker");

    function setUp() external {
        vm.createSelectFork("https://goerli.blockpi.network/v1/rpc/public"); 
        nft = new GoldNFT();
    }

    function test_Attack() public {
        vm.startPrank(hacker);

        exploiter attack = new exploiter(address(nft));
        attack.attack();

        // solution
        assertEq(nft.balanceOf(hacker), 10);
    }
}