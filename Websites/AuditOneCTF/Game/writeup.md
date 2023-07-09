**Issue category**
High

**Issue title**
Reentrancy in buyItem()

**Where**
buyItem()

**Impact**
A attacker can drain the whole contract

**Description**
buyItem() implements a check for the balances of the msg.sender being bigger thant the needed amount of ether. Then it casts the msg.sender address to the Player Interface and calls its receiveItem functionality. Then it deducts 0.00001 ether of the balance. The issue here is the outside call to the player after the check and before the deduction, without any reentrancy guard. 

Attack Scenario:_
1. Attacker deposits 0.000011 ether
2. Attacker calls buyItem() and passes first require
3. Game calls to the attackers' receiveItem() function
4. Attacker calls back to the withdrw() function and withdraws the 0.000011 ether again, then finishes the function
5. Game deducts 0.00001 ether from the balance of the attacker underflowing it (as compiler 0.6.0 is used) and granting the attacker an enormous balance
6. Attacker is able to call withdrwa with the value of everything that is stored in the contract and drain it.

**Recommendations to fix**
Do the call to player.receiveItem(item) after the balances[msg.sender] -= 0.00001 ether. New code:

```
function buyItem() public {
    require(balances[msg.sender] > 0.00001 ether);
    balances[msg.sender] -= 0.00001 ether;
    Item item = new Item();
    Player player = Player(msg.sender);
    player.receiveItem(item);
    //Item is activated after the paytment is made
    //Before activation, the item is worthless;
    item.activate(); //function activate() onlyOwner
}
```

**Additional context**
Add any other context about the problem here.

**Comments by AuditOne**
AuditOne team can comment here

--- 

**Issue category**
Low

**Issue title**
Stuck Balances

**Where**
withdrw()

**Impact**
Users will always have to leave 1 wei in their balance.

**Description**
As the amount withdrawn has to be smaller than the balance of the user, the user is only able to pass balances[msg.sender]-1 as _amount to withdraw().

**Recommendations to fix**
change 
```
require(balances[msg.sender] > _amount)
```

to

```
require(balances[msg.sender] >= _amount)
```

**Additional context**

**Comments by AuditOne**
AuditOne team can comment here

--- 

**Issue category**
Low

**Issue title**
Item Price not correctly checked

**Where**
buyItem()

**Impact**
Users will always have to have 1 wei more than they need to buy the item in their balance.

**Description**
The require in buyItem checks for the users balance being bigger than 0.00001 ether but it would also suffice if the user has exactly 0.00001 ether in his balance.

**Recommendations to fix**
change 

```
require(balances[msg.sender] > 0.00001 ether);
```

to

```
require(balances[msg.sender] >= 0.00001 ether);
```

**Additional context**

**Comments by AuditOne**
AuditOne team can comment here

---

**Issue category**
Low

**Issue title**
Return values not checked

**Where**
withdrw()

**Impact**
Value could be lost

**Description**
The withdrw() function doesn't check if the call to the fallback/receive function of msg.sende is succesfull. This should be checked so no money is lost.

**Recommendations to fix**
Check the return values of the call like this:

```solidity
    function withdrw(uint _amount) public {
        require(balances[msg.sender] > _amount);
        balances[msg.sender] -= _amount;
        (bool success, ) = msg.sender.call.value(_amount)("");
        require(success, "Withdrawing the money did not work.");
    }

```

**Additional context**

**Comments by AuditOne**
AuditOne team can comment here

---

**Issue category**
Informational

**Issue title**
Balance overflow in deposit

**Where**
deposit()

**Impact**
The balances could theoretically overflow.

**Description**
As compiler 0.6.0 is used and the addition to the value is not checked by any additional requires, the value could theoretically overflow. As it would not be doable to increase the value over the uint256_max, even if someone had all the ether in circulation, this should not be an issue.

**Recommendations to fix**
None needed

**Additional context**
UINT256_MAX = 115792089237316195423570985008687907853269984665640564039457584007913129639935

MAX_WEI (currently) = 120000000000000000000000000

UINT256_MAX > MAX_WEI

**Comments by AuditOne**
AuditOne team can comment here

----

**Issue category**
Informational

**Issue title**
Typo in Function Name

**Where**
withdrw()

**Impact**
Looks unprofessional

**Description**
There is a typo in the withdrw() function, it should probably be named withdraw()

**Recommendations to fix**
change the name to withdraw()

**Additional context**

**Comments by AuditOne**
AuditOne team can comment here

---

**Issue category**
Informational

**Issue title**
Function not declared as view

**Where**
getBalance()

**Impact**
Needs unneccesary gas

**Description**
The function getBalance() could also be declared as view to reduve its gas cost.

**Recommendations to fix**
Declare the function getBalance() as view like this:

```
function getBalance(address a) public view returns(uint) {
    return balances[a];
}
```

**Additional context**

**Comments by AuditOne**
AuditOne team can comment here

---- 

**Issue category**
Informational

**Issue title**
Functions could be declared as external

**Where**
deposit(), withdrw(), getBalance(), buyItem() 

**Impact**
Needs unneccesary gas

**Description**
The functions could eb declared as external, as they are never called from inside the contract

**Recommendations to fix**
Declare the functions as external instead of public

**Additional context**

**Comments by AuditOne**
AuditOne team can comment here

---- 