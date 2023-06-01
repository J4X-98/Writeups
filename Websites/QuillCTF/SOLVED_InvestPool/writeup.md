# Invest Pool

## Challenge

Description:
With liquidity pools, you can always trust that your investment is in good hands.

Objective of CTF:
Your objective is to have a greater token balance than your initial balance. You are a hacker, not the user. (see foundry test file)

We get 2 contracts:

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

Unfortunately the contracts storage only has the number 1, 1 and 5 inside. 

So i looked at the discord and found one of the admins hint to look at solidity metadata. I used https://playground.sourcify.dev/ to extract the metadata and got the ipfs url https://ipfs.io/ipfs/QmU3YCRfRZ1bxDNnxB4LVNCUWLs26wVaqPoQSQ6RH2u86V which yields us the password "j5kvj49djym590dcjbm7034uv09jih094gjcmjg90cjm58bnginxxx". This allowed us to finally initialize the contract.

The second part was exploiting the contract so that we got more tokens in the end. First there was a red hering, the function transferFromShare(). If this function would have been callable you could just let the user give all his money to the pool and then transfer his shares to you and withdraw. unfortunately there was also a check in assembly included that worked against this.

```solidity
uint size;
assembly {
    size := extcodesize(address())
}
require(size == 0, "code size is not 0");
```

This checks results in the function being unexecutable without triggering a revert. As this checks for the codesize of itself being greater than 0, and not being inside the constructor, this function can never be called as the extcodesize will always return > 0. 

As this function was unusable, i looked a bit closer at the 2 calculation functions. What also lead towards this suspicion is that to solve the challenge you didn't need to have all the users tokens, but just more than at the start. So i suspected an issue in the rounding of the division. The first thing that caught my eye is that the calculation will not work as intended if you just send tokens to the contract, without receiving shares. For example by using transfer(). I just tried random values and saw that it really got the values messed up. For the poc i then did multiple steps.

1. Get 1 share by depositing one token.

2. Send a lot of tokens (100e18) to the contract.

3. Let the user deposit his money into the contract.

```solidity
sharesHeShouldGet = 1000e18 * (100e18 + 1) / (100e18 + 1) = 1000e18
sharesHeGets      = 1000e18 * 1 / (100e18 + 1) = 1000e18 /(100e18 + 1) = 9 (because we round down)  
```

4. Call WithdrawAll() leading to a miscalculation, and yielding us more tokens than we should have got.

```solidity
tokensWeGet       =  1 * (1100e18 + 1) / 10 = (1100e18 + 1) / 10 = 1009999999999999999999
```