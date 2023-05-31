# WETH 11

## Challenge

Objective of CTF:
We have fixed WETH10 and now have introduced its new version WETH11.
But along the way, bob made a mistake and transferred its tokens to the wrong address.
Can you help bob recover his 10 ether?

We also get the code for WETH11:

```solidity
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// The Angel Di Maria Wrapped Ether
contract WETH11 is ERC20("Angel Di Maria Wrapped Ether", "WETH11"), ReentrancyGuard {
    receive() external payable {
        deposit();
    }

    function _burnAll() internal {
        _burn(msg.sender, balanceOf(msg.sender));
    }

    function deposit() public payable nonReentrant {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) external nonReentrant {
        _burn(msg.sender, wad);
        Address.sendValue(payable(msg.sender), wad);
       
    }

    function withdrawAll() external nonReentrant {
        uint256 balance = balanceOf(msg.sender);
        _burnAll();
        Address.sendValue(payable(msg.sender), balance);
        
    }

    /// @notice Request a flash loan in ETH
    function execute(address receiver, uint256 amount, bytes calldata data) external nonReentrant {
        uint256 prevBalance = address(this).balance;
        Address.functionCallWithValue(receiver, data, amount);

        require(address(this).balance >= prevBalance, "flash loan not returned");
    }
}
```

## Solution
In this chal we can exactly exploit what I mentioned as a vulnerability in WETH10. When we use the execute() function to get WETH10 to call a function on itself it can be used to transfer its token to bob. We can do that by calling execute with the address of WET11, an amount of 0 and the calldata for the transfer() function with bobs address and all the tokens. Then we just withdraw all as we now have all the tokens again. This can be done in 2 calls in the POC:

```solidity
weth.execute(address(weth), 0, abi.encodeWithSignature("transfer(address,uint256)", address(bob), 10 ether));
weth.withdrawAll();
```

After this we have all the money and pass the testcase.
