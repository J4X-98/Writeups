**Issue category**
High

**Issue title**
No Fee charged

**Where**
calculateFee() / executeExchange()

**Impact**
There is no fee charged on exchanges that are below totalCoins(which should be all in a correct implementation).

**Description**
the fee is calculated as (_coins / totalCoins) * exchangeFee. The Problem is that unsigned integers are used, so as it should always be the case that _coins < totalCoins, the result of the division is always rounded down to 0. This value multiplied with the variable exchangeFee is also always 0.

**Recommendations to fix**
Implement a multiplier, to reduce the amount of error in the calculation. This can be set according to the desired accuracy, in the example I used 1000000000000000000000000000 but this can be set as choosen.

```Solidity
uint256 public constant multiplier = 1000000000000000000000000000;

...

function calculateFee(uint _coins) public view returns (uint) {
    return ((_coins * multiplier / totalCoins) * exchangeFee) / multiplier;
}
```

**Additional context**
https://blog.solidityscan.com/precision-loss-in-arithmetic-operations-8729aea20be9

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
High

**Issue title**
Typo in the constructor

**Where**
consructor()

**Impact**
The code doesn't compile and can't be deployed.

**Description**
There is a typo in the constructor function. It is called consructor() instead of constructor(). This results in the code not compiling.

**Recommendations to fix**
Rename consructor() to constructor().

**Additional context**

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
High

**Issue title**
Typo in the require in setExchangeFee()

**Where**
setExchangeFee()

**Impact**
The code doesn't compile and can't be deployed.

**Description**
There is a typo in the require. Between the 2 arguments, it includes a point instead of a comma. So the code can't compile.

**Recommendations to fix**
Change:
```solidity
require(msg.sender == owner. "Only owner can set exchange fee.");
```

to 

```solidity
require(msg.sender == owner, "Only owner can set exchange fee.");
```

**Additional context**


**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
High

**Issue title**
No possible withdrawal by the owner

**Where**
Missing functionality.

**Impact**
All the fees will stay stuck in the contract forever.

**Description**
There is no function inside the contract, that allows the owner to withdraw the funds earned through fees.

**Recommendations to fix**
I would add a ownerWithdraw() function like this:

```solidity
function withdrawOwner(uint withdrawAmount) public {
    //Check for ownership 
    require(msg.sender == owner. "Only owner can withdraw money.");

    //Check if there is enough money in the contract (taking the setting to 1 in the constructor into account)
    require(withdrawAmount < totalCoins, "You are withdrawing more money than there is in the contract");

    //Reduce the totalCoins
    totalCoins -= withdrawAmount;

    //Send money to owner & check for success
    (bool success,) = payable(owner).call{value: withdrawAmount}("");
    require(success, "Withdraw failed");

    //Add a fitting emit here
}
```

**Additional context**


**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
High

**Issue title**
The change is sent to the owner instead of the user.

**Where**
executeExchange

**Impact**
Users don't receive any money/tokens back when they call the executeExchange function.

**Description**
After deducting the fee, the contract sends the left change to the owner instead of the user. 

**Recommendations to fix**
Send the change back to the user by changing

```solidity
payable(owner).transfer(change);
```

to

```soldity
payable(msg.sender).transfer(change);
```

**Additional context**

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
High

**Issue title**
executeExchange() is missing functionalities

**Where**
executeExchange()

**Impact**
It does not make any sense for a user to use this contract.

**Description**
The contract only takes users' money, keeps a fee, and then sends the rest of the money to its owner, without giving any benefit to the user.

**Recommendations to fix**
Implement a real functionality that brings value to customers. This could for example be to exchange the money sent by the user to a token that is issued by the contract. 

**Additional context**


**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
Medium

**Issue title**
TotalCoins is never updated

**Where**
executeExchange()

**Impact**
The total amount of coins never increases, which leads to faulty fee calculations.

**Description**
The variable totalCoins is once initialized in the constructor. As a lot of the documentation in the code is missing, this leaves some room for speculation as to how this variable should be used / what it should represent. As the name indicates it should probably track the amount of coins(wei) inside the contract. This is not the case, as the exchange takes a fee at every call to executeExchange() but doesn't increase the totalCoins() balance. 

**Recommendations to fix**
I would recommend the developer initialize the totalCoins variable to 1 in the constructor (not 0, so no division by 0 can happen in the calculateFee). Then I would recommend incrementing the counter each time a fee gets taken, by the fee.

constructor:
```soldidity
consructor(uint256 _totalCoins) {
    owner = msg.sender;
    exchangeFee = 40;
    totalCoins = 1;
}
```

executeExchange:
```soldidity
function executeExchange(uint _coins) public payable {
    uint fee = calculateFee(_coins);
    totalCoins += fee;
    require(msg.value >= fee, "Insufficient exchange fee.");
    uint change = msg.value - fee;
    if (change > 0) {
        payable(owner).transfer(change);
    }
}
```

**Additional context**

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
Medium

**Issue title**
Missing check for 0 in the constructor

**Where**
consructor()

**Impact**
Unintended values for _totalCoins could be entered and mess up the business logic.

**Description**
There are no checks for unintended values being provided as totalCoins. If for example 0 would be provided, the whole contract would be broken as there would be a division by 0 in the calculateFee() function, which would always lead to the function reverting. This would also not be fixable as there is no way to change the value of totalCoins.

**Recommendations to fix**
Add a require to the constructor like this:
```solidity
consructor(uint256 _totalCoins) {
    require(_totalCoins != 0, "totalCoins has to be more than zero!");
    owner = msg.sender;
    exchangeFee = 40;
    totalCoins = _totalCoins;
}
```

**Additional context**

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
Low

**Issue title**
Use of transfer()

**Where**
executeExchange()

**Impact**
Possibility for reentrancy vulnerabilities.

**Description**
The transfer() function is used in the executeExchange() function to send the change to the owner. This function should not be used anymore as it allows for reentrancy vulnerabilities.

**Recommendations to fix**
Replace the function call with:

```solidity
(bool success,) = payable(owner).call{value: change}("");
require(success, "Exchange failed");
```

**Additional context**
https://www.immunebytes.com/blog/transfer-in-solidity-why-you-should-stop-using-it/

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
Low

**Issue title**
Ownership lacks standard functionality

**Where**
Exchange.sol

**Impact**
Ownership can't be renounced/transferred.

**Description**
The contract initializes the owner variable once which can never be changed.

**Recommendations to fix**
Use an established ownership library like OpenZeppelins [Ownable.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol) if additional functionalities are desired.

**Additional context**

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
Informational

**Issue title**
No checks in setExchangeFee()

**Where**
setExchangeFee()

**Impact**
The fee can be set to 0 or arbitrarily high.

**Description**
There are no checks on the _fee parameter in setExchangeFee(). So the owner can set the fee to 0 or so high that no transaction would be possible anymore (if the calculation works correctly). As this could also be intended or unintended, which is unclear due to missing documentation, I wanted to still mention it.

**Recommendations to fix**
If this is unintended I would add requires in the function that restrict the fee to a certain range.
```solidity
    function setExchangeFee(uint _fee) public {
        require(_fee != 0, "Fee can never be zero!");
        require(_fee < 1000, "Fee can never be greater than 1000!");
        ...
    }
```
**Additional context**


**Comments by AuditOne**
AuditOne team can comment here


----

**Issue category**
QA

**Issue title**
Missing Emits

**Where**
All over the contract

**Impact**
Monitoring is harder once deployed.

**Description**
The contract doesn't emit any events in case of exchanges, etc. This makes monitoring the contract, once deployed, harder than needed.

**Recommendations to fix**
Add events & emit for setExchangeFee() and executeExchange(). These should include the newly set fee for setExchangeFee() and the amount exchanged as well as the fee paid for executeExchange().

**Additional context**
https://www.tutorialspoint.com/solidity/solidity_events.htm

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
QA

**Issue title**
Functions can be marked as external

**Where**
setExchangeFee() / executeExchange()

**Impact**
Gas inefficiency

**Description**
The functions setExchangeFee() and executeExchange() are never called from within the contract and are marked as public, which results in wasted gas. 

**Recommendations to fix**
Change both functions declarations to external like this:

```solidity
function setExchangeFee(uint _fee) external {
    ...
}

function executeExchange(uint _coins) external payable {
    ...
}
```

**Additional context**
https://gus-tavo-guim.medium.com/public-vs-external-functions-in-solidity-b46bcf0ba3ac

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
QA

**Issue title**
Unset Visibility of totalCoins

**Where**
totalCoins

**Impact**
The variable totalCoins is initialized as internal (maybe unintended).

**Description**
No visibility is set for the variable totalCoins. This results in the variable being initialized with the default visibility internal, which might not be intended.

**Recommendations to fix**
Set a visibility for the variable.

**Additional context**

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
QA

**Issue title**
The owner can be set as constant

**Where**
consructor()

**Impact**
Unnecessary gas usage.

**Description**
The owner variable is only set in the constructor and can't be changed afterward. This leads to unnecessary gas usage.

**Recommendations to fix**
Set the variable to immutable:
```solidity
address public immutable owner;
```

**Additional context**
https://solidity-by-example.org/immutable/

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
QA

**Issue title**
Variables can be delared as uint256

**Where**
exchangeFee & totalCoins

**Impact**
The source code is harder to understand. 

**Description**
The 2 variables exchangeFee & totalCoins are declared as uint. This automatically maps to uint256, but this might not be clear to someone working on the code later. 

**Recommendations to fix**
To make the code easier to understand declare both variables as uint256.
```solidity
uint256 public exchangeFee;
uint256 totalCoins;
```

**Additional context**
https://www.alchemy.com/overviews/solidity-uint#:~:text=Uint%20Data%20Sizes&text=An%20unsigned%20integer%20value%20data,%2C%20uint64%2C%20uint128%20and%20uint256.

**Comments by AuditOne**
AuditOne team can comment here


----

**Issue category**
QA

**Issue title**
Non-Fixed Solidity version

**Where**
Pragma

**Impact**
Possible compilation with an old version of solidity.

**Description**
The pragma is not fixed to a certain version but is set to a version newer than 0.8.0. 

**Recommendations to fix**
Set the version to the newest available version of the solidity compiler. This currently is version 0.8.21. This can be achieved by changing the pragma to:

```solidity
pragma solidity 0.8.21;
```

**Additional context**
https://www.oreilly.com/library/view/mastering-blockchain-programming/9781839218262/d1250994-b952-4d5e-9cde-1b852c18b55f.xhtml

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
QA

**Issue title**
Missing Documentation

**Where**
Exchange.sol 

**Impact**
The code is hard to understand.

**Description**
The code doesn't contain any comments or additional documentation on which behavior is intended or needed.

**Recommendations to fix**
Add Comments to the code as well as provide additional documentation on the intended behavior. The comments should follow the solidity natspec syntax.

**Additional context**
https://docs.soliditylang.org/en/develop/natspec-format.html

**Comments by AuditOne**
AuditOne team can comment here