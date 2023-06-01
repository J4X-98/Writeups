// Description:
// A short script that lets you read out the storage of a smart contract

// Fill in these values before running the script
const RPC_URL = 'https://rpc.ankr.com/eth_goerli'; // Replace with the RPC URL of the network you're using
const CONTRACT_ADDRESS = '0xA45aC53E355161f33fB00d3c9485C77be3c808ae'; // Replace with the address of the contract you're targeting
const STORAGE_SLOT = '0'; // Replace with the storage slot you want to read out

// Import the web3.js library
const Web3 = require('web3');

// Set up the web3 provider using the RPC URL and chain ID of the custom blockchain
const web3 = new Web3(new Web3.providers.HttpProvider(RPC_URL));

// Get the storage value at a specific address and position
async function getStorageAt(address, position) {
  try {
    const storageValue = await web3.eth.getStorageAt(address, position);
    console.log(`Storage value at address ${address} and position ${position}: ${storageValue}`);
  } catch (error) {
    console.error(error);
  }
}

// Call the getStorageAt function with the specified contract address and storage slot
async function main()
{
  await getStorageAt(CONTRACT_ADDRESS, 0);
  await getStorageAt(CONTRACT_ADDRESS, 1);
  await getStorageAt(CONTRACT_ADDRESS, 2);
  await getStorageAt(CONTRACT_ADDRESS, "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470");
}

main();
