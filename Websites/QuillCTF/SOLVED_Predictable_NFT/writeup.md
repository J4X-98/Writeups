# Predictable NFT

## Challenge

We receive a address on goerli and a poc snippet:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.19;

import "forge-std/Test.sol";

contract PredictableNFTTest is Test {
	address nft;

	address hacker = address(0x1234);

	function setUp() public {
		vm.createSelectFork("goerli");
		vm.deal(hacker, 1 ether);
		nft = address(0xFD3CbdbD9D1bBe0452eFB1d1BFFa94C8468A66fC);
	}

	function test() public {
		vm.startPrank(hacker);
		uint mintedId;
		uint currentBlockNum = block.number;

		// Mint a Superior one, and do it within the next 100 blocks.
		for(uint i=0; i<100; i++) {
			vm.roll(currentBlockNum);

			// ---- hacking time ----

			currentBlockNum++;
		}

		// get rank from `mapping(tokenId => rank)`
		(, bytes memory ret) = nft.call(abi.encodeWithSignature(
			"tokens(uint256)",
			mintedId
		));
		uint mintedRank = uint(bytes32(ret));
		assertEq(mintedRank, 3, "not Superior(rank != 3)");
	}
}
```


## Solution
As we don't have any source code for this chall i first started by decompiling the bytecode of the given address. I used Palkeoramix decompiler (included in Etherscan) for this, which gave me the pseudocode:
```solidity
# Palkeoramix decompiler. 

def storage:
  id is uint256 at storage 0
  tokens is mapping of uint256 at storage 1

def tokens(uint256 _param1): # not payable
  require calldata.size - 4 >=ΓÇ▓ 32
  return tokens[_param1]

def id(): # not payable
  return id

#
#  Regular functions
#

def _fallback() payable: # default function
  revert

def mint() payable: 
  if call.value != 10^18:
      revert with 0, 'show me the money'
  if id > id + 1:
      revert with 0, 17
  id++
  if sha3(id, caller, block.number) % 100 > 90:
      tokens[stor0] = 3
  else:
      if sha3(id, caller, block.number) % 100 <= 80:
          tokens[stor0] = 1
      else:
          tokens[stor0] = 2
  return id
```

As this code couln't be directly run like this i cleaned it up a bit:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.19;

contract NFT
{
    uint256 id;
    mapping(uint256 => uint256) tokens;

    function mint() public payable returns (uint256)
    {
        require(msg.value == 10^18, "show me the money");
        require(id < id + 1, "Overflow");

        id = id + 1;

        if((uint256(sha256(abi.encodePacked(id, msg.sender, block.number))) % 100) > 90)
        {
            tokens[id] = 3;
        }
        else
        {
            if((uint256(sha256(abi.encodePacked(id, msg.sender, block.number))) % 100) <= 80)
            {
                tokens[id] = 1;
            }
                
            else
            {
                tokens[id] = 2;
            }
        }
        return id;
    }
}
``

So it's pretty easy. You can just use the same function as the challenge uses (sha256 not keccak256) and see which hash to the modulo of 100 will be above 90.

## POC

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.19;

import "forge-std/Test.sol";

contract PredictableNFTTest is Test {
	address nft;

	address hacker = address(0x1234);

	function setUp() public {
		vm.createSelectFork("goerli");
		vm.deal(hacker, 1 ether);
		nft = address(0xFD3CbdbD9D1bBe0452eFB1d1BFFa94C8468A66fC);
	}

	function test() public {
		vm.startPrank(hacker);
		uint mintedId;
		uint currentBlockNum = block.number;

		// Mint a Superior one, and do it within the next 100 blocks.
		for(uint i=0; i<100; i++) {
			vm.roll(currentBlockNum);

			// ---- hacking time ----

            if((uint256(sha256(abi.encodePacked(uint256(0), hacker, currentBlockNum))) % 100) > 90 && mintedId == 0)
            {
				nft.call{value: 1 ether}(abi.encodeWithSignature("mint()"));
				mintedId = 1;
            }

			currentBlockNum++;
		}

		// get rank from `mapping(tokenId => rank)`
		(, bytes memory ret) = nft.call(abi.encodeWithSignature(
			"tokens(uint256)",
			mintedId
		));
		uint mintedRank = uint(bytes32(ret));
		assertEq(mintedRank, 3, "not Superior(rank != 3)");
	}
}
```

