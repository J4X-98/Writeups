# Deception

## Challenge

We once again use the ParadigmCTF Framework.

We are provided with a contract called Deception.sol

```solidity
// Contract that has to be displayed for challenge

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract deception{
    address private owner;
    bool public solved;

    constructor() {
      owner = msg.sender;
      solved = false;
    }

    modifier onlyOwner() {
      require(msg.sender==owner, "Only owner can access");
      _;
    }

    function changeOwner(address newOwner) onlyOwner public{
      owner = newOwner;
    }

    function password() onlyOwner public view returns(string memory){
        return "secret";
    }

    function solve(string memory secret) public {
      require(keccak256(abi.encodePacked(secret))==0x65462b0520ef7d3df61b9992ed3bea0c56ead753be7c8b3614e0ce01e4cac41b, "invalid");
      solved = true;
    }
}
```

Our goal is to get the value solved to true.

## Solution

The challenge seems pretty straightforward. I checked and the keccak256 of "secret" was the value needed below. So you seem to only need to use this value and call the function to solve it. Unfortunately, this didn't work and I always got a revert.

As I thought I was messing up something on my side, it took me some time until I pulled the bytecode using cast like this:

```bash
cast code $target_contract --rpc-url $rpc
```
After decompilation using the [Dedaub decompiler](https://library.dedaub.com/decompile) I saw that the solve function in the deployed version checks for a different hash (db91bc5e087269e83dad667aa9d10c334acd7c63657ca8a58346bb89b9319348). I then used hashcat with rockyou.txt to find a preimage for the hash using the command 

```bash
hashcat -m 17800 -a 0 -o cracked.txt db91bc5e087269e83dad667aa9d10c334acd7c63657ca8a58346bb89b9319348 ./rockyou.txt
```

This only took a few seconds and yielded me the password "xyzabc". I then used Foundry's cast to solve the challenge as seen below.

```bash
# uuid:           6dfbdb77-269e-44c6-afa4-f920b7927506
# rpc endpoint:   http://146.148.125.86:60082/6dfbdb77-269e-44c6-afa4-f920b7927506
# private key:    0x26c2140e5ba08f5a9bcfd619936cd38638454015dbbfcccb0b46bdec176334b2
# setup contract: 0x26b6EFC2064772E0a309990C7ED2C5Fab155e16b

rpc="http://146.148.125.86:60082/6dfbdb77-269e-44c6-afa4-f920b7927506"
priv_key=0x26c2140e5ba08f5a9bcfd619936cd38638454015dbbfcccb0b46bdec176334b2
setup_contract=0x26b6EFC2064772E0a309990C7ED2C5Fab155e16b

# Get the address of the deployed contract
cast call $setup_contract "TARGET()(address)" --rpc-url $rpc

# Target is at 0xdD461A87A880878f42F0c41A35cE9Afc81558A06
target_contract=0xdD461A87A880878f42F0c41A35cE9Afc81558A06

# call its solve with the right string
cast send $target_contract "solve(string)" "xyzabc" --private-key $priv_key --rpc-url $rpc

# Check if it was solved
cast call $setup_contract "isSolved()(bool)" --rpc-url $rpc
```

This gets us the flag crew{d0nt_tru5t_wh4t_y0u_s3e_4s5_50urc3!}.