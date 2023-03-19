# Disclosure - Web3

## The Challenge

There are 2 contracts. The first one is the Filesmanager, which is used for savinf file URIs as NFTs on the blockchain.

```
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// The following contract is vulnerable on purpose: DO NOT COPY AND USE IT ON MAINNET!
contract FilesManager is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    address public owner;
    string public ownerName;

    constructor(string memory _name, address _owner) ERC721("Files", "FLS") {
        ownerName = _name;
        owner = _owner;
    }

    function mintNewToken(string memory metadataUri) public {
        require(msg.sender == owner);
        tokenIds.increment();
        uint256 newId = tokenIds.current();
        _mint(owner, newId);
        _setTokenURI(newId, metadataUri);
    }
}
```

THe second contract is the FilesManagerDeployer which you can use to deploy new FilesManager contracts. We get this contracts address in the challenge. 

```
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./FilesManager.sol";

// The following contract is vulnerable on purpose: DO NOT COPY AND USE IT ON MAINNET!
contract FilesManagerDeployer {
    function createNewFileManagerFor(string memory name) public returns(address) {
        return address(new FilesManager(name, msg.sender));
    }
}
```
The goal of this challenge is to retrieve the files that were minted in a filesmanager that was deployed before we got the address.

## Solution

Throughout i used the same scipt multiple times and adapted it according to the address i was investigating. The script is used to find transactions goin from/to an address.

```
const Web3 = require('web3');
const web3 = new Web3('http://sie2op7ohko.hackday.fr:8545');
// const ADDRESS = '0xbDb0eE8217d0A611419Af60b8471EE4183E1101a'; Old
const ADDRESS = '0x3E57B4A012B80232097F5488f926A89692B4Cd04';  //Me

async function getTransactionHistory() {
  try {
    const latestBlock = await web3.eth.getBlockNumber();
    const history = [];
    for (let i = latestBlock; i >= 0; i--) {
      const block = await web3.eth.getBlock(i, true);
      if (block && block.transactions) {
        const transactions = block.transactions.filter(
          (tx) => (tx.from && tx.from.toLowerCase() === ADDRESS.toLowerCase()) || (tx.to && tx.to.toLowerCase() === ADDRESS.toLowerCase())
        );
        transactions.forEach((tx) => {
          console.log(`Block Number: ${block.number}`);
          console.log(`Transaction Hash: ${tx.hash}`);
          console.log(`From: ${tx.from}`);
          console.log(`To: ${tx.to}`);
          console.log(`Value: ${tx.value}`);
          console.log(`Gas Price: ${tx.gasPrice}`);
          console.log(`Gas Used: ${tx.gas}`);
          console.log(`Timestamp: ${block.timestamp}`);
          console.log(`----------------------------------`);
        });
      }
      if (i % 100 == 0)
      {
        console.log(i);
        }
    }
  } catch (error) {
    console.error(error);
  }
}

web3.eth.net.getId((err, netId) => {
  if (err) {
    console.error('Error getting network ID:', err);
    return;
  }
  console.log(`Connected to network ID ${netId}`);
  getTransactionHistory();
});
```

Using this script and investigating the FilesManagerDeployer address i found the address of the main contract that deployed our contract. Using this address i started looking at other contracts that were created by this "main" address and checked if they had the same ABI as a fileManager. I found 3 different fileManager contracts belonging to different people (Vivy PULSAR, Yugo SUPERNOVA, Elsa METEORA). You can now use the tokenURI() to get the URIs for all files that were minted in these contracts. One of these includes the flag.

--> Flag