# Challenge 00 : Oh sh. Here we go again ? - Blockchain

## Challenge

We are only provided with an address and a RPC URL.


## Solution

I started by reading out the bytecode for the address, for which i just wrote a small web3 script:

```js
const Web3 = require('web3');
const rpcUrl = 'http://62.171.185.249:8502'; // Replace with your custom RPC URL
const web3 = new Web3(rpcUrl);

const contractAddress = '0x3038ae6af5726f685B551266d8cCd704e7e0c3CA'; // Replace with the address of the contract you want to retrieve bytecode for

web3.eth.getCode(contractAddress, (error, bytecode) => {
  if (error) {
    console.error('Error retrieving contract bytecode:', error);
  } else {
    console.log('Contract bytecode:', bytecode);
  }
});
```

this got me the following bytecode:

```
0x608060405234801561001057600080fd5b50600436106100575760003560e01c80633c5269d81461005c578063459a279014610066578063473ca96c1461008457806375ec067a146100a2578063e9a37061146100ac575b600080fd5b6100646100ca565b005b61006e6100e6565b60405161007b9190610184565b60405180910390f35b61008c6100f9565b6040516100999190610184565b60405180910390f35b6100aa610127565b005b6100b4610158565b6040516100c19190610184565b60405180910390f35b60016000806101000a81548160ff021916908315150217905550565b600060019054906101000a900460ff1681565b60008060009054906101000a900460ff1680156101225750600060019054906101000a900460ff165b905090565b60008054906101000a900460ff1615610156576001600060016101000a81548160ff0219169083151502179055505b565b60008054906101000a900460ff1681565b60008115159050919050565b61017e81610169565b82525050565b60006020820190506101996000830184610175565b9291505056fea2646970667358221220410b70e32943a11347a432c640d65c5ccae8006bc0dbc6dd7ba624c219c0059264736f6c63430008110033
```

I then used an online decompiler(library.dedaub.com) to decompile the bytecode to this:

```solidity
// Decompiled by library.dedaub.com
// 2023.05.12 19:25 UTC
// Compiled using the solidity compiler version 0.8.17


// Data structures and variables inferred from the use of storage instructions
uint256 _win; // STORAGE[0x0] bytes 0 to 0
uint256 stor_0_1_1; // STORAGE[0x0] bytes 1 to 1

function () public payable { 
    revert();
}

function 0x3c5269d8() public payable { 
    _win = 1;
}

function 0x459a2790() public payable { 
    return stor_0_1_1;
}

function win() public payable { 
    v0 = v1 = _win;
    if (v1) {
        v0 = stor_0_1_1;
    }
    return bool(v0);
}

function 0x75ec067a() public payable { 
    if (_win) {
        stor_0_1_1 = 1;
    }
}

function 0xe9a37061() public payable { 
    return _win;
}
```

There seemed to be a win() function and 2 functions that overwrite state variables (0x3c5269d8, 0x75ec067a). THe second one seemed to only change if _win was already set in the first one, so I just called them in this order.

1. 0x3c5269d8
2. 0x75ec067a

Now the win() function returns true and the challenge is solved. -> Hero{M3l_weLComes_U_B4cK!:)}


## Bonus

After the CTF the original source code was also released:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract hero2300 {
    bool public firstFlag;
    bool public secondFlag;

    constructor() {
        firstFlag = false;
        secondFlag = false;
    }

    function meFirst() public {
        firstFlag = true;
    }

    function meSecond() public {
        if (firstFlag) {
            secondFlag = true;
        }
    }

    function win() public view returns (bool) {
        return (firstFlag && secondFlag);
    }

}
```