# Invest Pool

## Challenge
We get 2 contracts. 

### InvestPool
```
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract InvestPool {
    IERC20 token;
    uint totalShares;
    bool initialized;
    mapping(address => uint) public balance;

    modifier onlyInitializing() {
        require(initialized, "Not initialized! You are so stupid!");
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
    }

    function initialize(string memory password) external {
        // Password could be found in Goerli contract
        // 0xA45aC53E355161f33fB00d3c9485C77be3c808ae
        // Hint: Password length is more than 30 chars
        require(!initialized, "Already initialized");
        require(
            keccak256(abi.encode(password)) ==
                0x18617c163efe81229b8520efdba6384eb5c6d504047da674138c760e54c4e1fd,
            "Wrong password"
        );
        initialized = true;
    }

    function deposit(uint amount) external onlyInitializing {
        uint userShares = tokenToShares(amount);
        balance[msg.sender] += userShares;
        totalShares += userShares;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function tokenToShares(uint userAmount) public view returns (uint) {
        uint tokenBalance = token.balanceOf(address(this));
        if (tokenBalance == 0) return userAmount;
        return (userAmount * totalShares) / tokenBalance;
    }

    function sharesToToken(uint amount) public view returns (uint) {
        uint tokenBalance = token.balanceOf(address(this));
        return (amount * tokenBalance) / totalShares;
    }

    function transferFromShare(uint amount, address from) public {
        uint size;
        assembly {
            size := extcodesize(address())
        }
        require(size == 0, "code size is not 0");
        require(balance[from] >= amount, "amount is too big");
        balance[from] -= amount;
        balance[msg.sender] += amount;
    }

    function withdrawAll() external onlyInitializing {
        uint shares = balance[msg.sender];
        uint toWithdraw = sharesToToken(shares);
        balance[msg.sender] = 0;
        totalShares -= shares;
        token.transfer(msg.sender, toWithdraw);
    }
}
```

### PoolToken

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PoolToken is ERC20("loan token", "lnt"), Ownable {
    function mint(uint amount) external onlyOwner {
        _mint(msg.sender, amount);
    }
}
```

Your objective is to have a greater token balance than your initial balance. We also get a dummy poc cotract using forge.

## Solution

I started by trying to get the password. For this i just used my template reader (https://github.com/J4X-98/SolidityCTFToolkit/blob/main/web3.js/reader.js) and adapted the script to the contract:

```
// Description:
// A short script that lets you read out the storage of a smart contract

// Fill in these values before running the script
const RPC_URL = 'https://eth-goerli.public.blastapi.io	'; // Replace with the RPC URL of the network you're using
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
getStorageAt(CONTRACT_ADDRESS, 0);
getStorageAt(CONTRACT_ADDRESS, 1);
getStorageAt(CONTRACT_ADDRESS, 2);
```
Unfortunately the contracts storage only has the number 1, 1 and 5 inside. So i looked at the discord and found one of the admins hint to look at solidity metadata. I used https://playground.sourcify.dev/ to extract the metadata and got the ipfs url https://ipfs.io/ipfs/QmU3YCRfRZ1bxDNnxB4LVNCUWLs26wVaqPoQSQ6RH2u86V which yields us the password "j5kvj49djym590dcjbm7034uv09jih094gjcmjg90cjm58bnginxxx".

## POC