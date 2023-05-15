# Gold NFT

## Challenge

We receive the contract:

```
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

```
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

```

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

So the read functions checks if a certain storage slot has been set to something else then 0. So i looked at the contract in etherscan. There wwe can see that the storage slot at 0x89cc2652e31add2270f7ce9c3c69ce903558b7a053665c92e066089aece0ccb6 was set to 1. 