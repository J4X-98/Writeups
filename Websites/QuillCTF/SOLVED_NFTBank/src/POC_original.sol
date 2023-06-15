// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/Test.sol";
import {NFTBank} from "../src/NFTBank.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract CryptoKitties is ERC721("CryptoKitties", "MEOW"), Ownable {
    function mint(address to, uint id) external onlyOwner {
        _safeMint(to, id);
    }
}

contract NFTBankHack is Test {
    NFTBank bank;
    CryptoKitties meow;
    address nftOwner = makeAddr("nftOwner");
    address attacker = makeAddr("attacker");

    function setUp() public {
        vm.startPrank(nftOwner);
        bank = new NFTBank();
        meow = new CryptoKitties();
        for (uint i; i < 10; i++) {
            meow.mint(nftOwner, i);
            meow.approve(address(bank), i);
            bank.addNFT(address(meow), i, 2 gwei, 500 gwei);
        }
        vm.stopPrank();
    }

    function test() public {
        vm.deal(attacker, 1 ether);
        vm.startPrank(attacker);
        bank.rent{value: 500 gwei}(address(meow), 1);
        vm.warp(block.timestamp + 86400 * 10);
        //solution       
        vm.stopPrank();
        assertEq(attacker.balance, 1 ether);
        assertEq(meow.ownerOf(1), attacker);
    }
}