// Import the web3.js library
const Web3 = require('web3');

// Set up the web3 provider using the RPC URL and chain ID of the custom blockchain
const web3 = new Web3(new Web3.providers.HttpProvider('https://goerli.blockpi.network/v1/rpc/public	'));

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
getStorageAt('0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66', 0);
getStorageAt('0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66', 1);
getStorageAt('0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66', 2);
getStorageAt('0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66', 3);
getStorageAt('0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66', 4);
getStorageAt('0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66', 5);
getStorageAt('0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66', 6);
getStorageAt('0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66', 7);
getStorageAt('0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66', 8);
getStorageAt('0xf8e9327e38ceb39b1ec3d26f5fad09e426888e66', 9);