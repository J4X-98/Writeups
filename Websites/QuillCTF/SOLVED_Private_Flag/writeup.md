# Private Flag

## Challenge 

We get the follwing contract, and want to retrieve the flag:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract private_flag{
    string public name = "Anon";
    string private Address = "Private";
    uint8 public age = 13;
    address public wallet = 0x0000000000000000000000000000000000001337;
    uint48 private favourite_number = 1337;
    bytes32[4] private Hashes;
    uint16 public num1 = 1;
    uint16 private num2 = 2;
    bool private Pwn = false;
    bool private pWn = false;
    bool private pwN = false;
    string private secret_flag = .................[REDACTED]...................
    address public owner;
}
```

## Solution

I could have nicely calculated where exactly the flag is, or do it the dirty way and just retrieve the first 10 storage slots and look for something that looks like ascii (which is exactly what i did);

```js
// Description:
// A short script that lets you read out the storage of a smart contract

// How to use:
// 1. Change the RPC URL to the one of the network you're using
// 2. Replace the first parameter of getStorageAt with the address of the contract you're targeting
// 3. Change the second parameter to the storage slot you want to read out.

// Import the web3.js library
const Web3 = require('web3');

// Set up the web3 provider using the RPC URL and chain ID of the custom blockchain
const web3 = new Web3(new Web3.providers.HttpProvider('https://rpc2.sepolia.org	'));

// Get the storage value at a specific address and position
async function getStorageAt(address, position) {
  try {
    const storageValue = await web3.eth.getStorageAt(address, position);
    console.log(`Storage value at address ${address} and position ${position}: ${storageValue}`);
  } catch (error) {
    console.error(error);
  }
}

// Call the getStorageAt function with a specific address and position
for (let i = 0; i < 10; i++) {
    getStorageAt('0xa907dd350eea49d9a8c2c5f58ef1f7a14015cce3', i);
}
```

which gets me the flag "flag{7h3_d3c3n7r4liz3d_w3b}" at storage slot 8.