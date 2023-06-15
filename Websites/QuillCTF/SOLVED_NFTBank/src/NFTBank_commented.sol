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
        //
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
        //NOTE: Checks if the msg.sender is the owner of the NFT
        if (msg.sender != nfts[collection][id].owner) revert YouAreNotOwner();

        //NOTE: Transfers the NFT to the msg.sender
        IERC721(collection).safeTransferFrom(address(this), msg.sender, id);

        //NOTE: Transfers the collected fee to the transferFeeTo address
        transferFeeTo.transfer(collectedFee[collection][id]);
    }

    function rent(address collection, uint id) external payable {
        //NOTE: Transfer NFT to the msg.sender
        IERC721(collection).safeTransferFrom(address(this), msg.sender, id);

        //NOTE: Checks if the msg.value is equal to the startRentFee
        if (msg.value != nfts[collection][id].startRentFee)
            revert WrongETHValue();

        //NOTE: Generates the rentData struct and pushes it to the back of the rentNFTs list
        rentNFTs.push(
            rentData({
                collection: collection,
                id: id,
                startDate: block.timestamp
            })
        );
    }

    function refund(address collection, uint id) external payable nonReentrant {
        
        //NOTE: NFT is returned.
        IERC721(collection).safeTransferFrom(msg.sender, address(this), id);

        //NOTE: Generates the rentData struct
        rentData memory rentedNft = rentData({
            collection: address(0),
            id: 0,
            startDate: 0
        });

        //NOTE: saves the rentData struct to the id & collection into rentedNFT
        //NOTE: Interstingly doesn't break after (maybe gas, maybe more)
        for (uint i; i < rentNFTs.length; i++) {
            if (rentNFTs[i].collection == collection && rentNFTs[i].id == id) {
                rentedNft = rentNFTs[i];
            }
        }

        //NOTE: Calculates the amount of days the NFT was rented for (min is 1)
        uint daysInRent = (block.timestamp - rentedNft.startDate) / 86400 > 1
            ? (block.timestamp - rentedNft.startDate) / 86400
            : 1;

        //NOTE: Calculates the rent fee by multiplying the days with the rentFeePerDay
        uint amount = daysInRent * nfts[collection][id].rentFeePerDay;

        //NOTE: Checks if the amount is equal to the msg.value
        if (msg.value != amount) revert WrongETHValue();

        //NOTE: Loops over the code again to get the index of the retunred NFT
        //NOTE: Gas waste
        uint index;
        for (uint i; i < rentNFTs.length; i++) {
            if (rentNFTs[i].collection == collection && rentNFTs[i].id == id) {
                index = i;
            }
        }

        //NOTE: Increases the collectedFee for the NFT
        collectedFee[collection][id] += amount;

        //NOTE: Transfers the rent fee to the owner of the NFT
        //NOTE: SuperOmegaFucked lines
        payable(msg.sender).transfer(
            nfts[rentNFTs[index].collection][rentNFTs[index].id].startRentFee
        );

        //NOTE: Some fuckery going on here
        rentNFTs[index] = rentNFTs[rentNFTs.length - 1];
        rentNFTs.pop();
    }
}