# Confidential Hash

## Challenge

We once again get only one contract:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Confidential {
    string public firstUser = "ALICE";
    uint public alice_age = 24;
		bytes32 private ALICE_PRIVATE_KEY; //Super Secret Key
    bytes32 public ALICE_DATA = "QWxpY2UK";
    bytes32 private aliceHash = hash(ALICE_PRIVATE_KEY, ALICE_DATA);

    string public secondUser = "BOB";
    uint public bob_age = 21;
    bytes32 private BOB_PRIVATE_KEY; // Super Secret Key
    bytes32 public BOB_DATA = "Qm9iCg";
    bytes32 private bobHash = hash(BOB_PRIVATE_KEY, BOB_DATA);
		
		constructor() {}

    function hash(bytes32 key1, bytes32 key2) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(key1, key2));
    }

    function checkthehash(bytes32 _hash) public view returns(bool){
        require (_hash == hash(aliceHash, bobHash));
        return true;
    }
}
```

Our goal is to find the keccak256 hash of aliceHash and bobHash.

## Solution

Here we will need a bit more than just calling functions in remix. It's nevrtheless not that hard. First we will use a simple web3.js script for reading out the storage of the contract. I used my example script (https://github.com/J4X-98/SolidityCTFToolkit/blob/main/helpers/web3.js/reader.js)

This yields us the (sorted) output

```
Storage value at address 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 and position 0: 0x414c49434500000000000000000000000000000000000000000000000000000a 
Storage value at address 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 and position 1: 0x0000000000000000000000000000000000000000000000000000000000000018 
Storage value at address 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 and position 2: 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 
Storage value at address 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 and position 3: 0x515778705932554b000000000000000000000000000000000000000000000000 
Storage value at address 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 and position 4: 0x448e5df1a6908f8d17fae934d9ae3f0c63545235f8ff393c6777194cae281478 
Storage value at address 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 and position 5: 0x424f420000000000000000000000000000000000000000000000000000000006
Storage value at address 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 and position 6: 0x0000000000000000000000000000000000000000000000000000000000000015
Storage value at address 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 and position 7: 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
Storage value at address 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 and position 8: 0x516d396943670000000000000000000000000000000000000000000000000000
Storage value at address 0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66 and position 9: 0x98290e06bee00d6b6f34095a54c4087297e3285d457b140128c1c2f3b62a41bd
```

So if we concise this down to a more readable format, using the storage strucutre we know from the contract we get:

```
0: firstUser = 0x414c494345 ("ALICE")
1: alice_age = 0x18 (24)
2: ALICE_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 
3: ALICE_DATA = 0x515778705932554b ("QWxpY2UK")
4: aliceHash = 0x448e5df1a6908f8d17fae934d9ae3f0c63545235f8ff393c6777194cae281478
5: secondUser = 0x424f42 ("BOB")
6: bob_age = 0x15 (21)
7: BOB_PRIVATE_KEY = 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6
8: BOB_DATA = 0x516d39694367 ("Qm9iCg")
9: bobHash = 0x98290e06bee00d6b6f34095a54c4087297e3285d457b140128c1c2f3b62a41bd

```

We have now leaked pretty much all sensitive information in the contract. To finish this off we just need to call the hash function of the contract with both the hashes we extracted, which gives us back the hash 0x9ef416df0fda1100f986a774a4b5e98862857d91600d4f615de7187c70d2b7bf. If we send this hash to checkTheHash we get back true, so we have solved the challenge.