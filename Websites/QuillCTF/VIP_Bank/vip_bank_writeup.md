# VIP Bank

## Challenge

We get a contract 

```
// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract VIP_Bank{
    address public manager;
    mapping(address => uint) public balances;
    mapping(address => bool) public VIP;
    uint public maxETH = 0.5 ether;

    constructor() {
        manager = msg.sender;
    }

    modifier onlyManager() {
        require(msg.sender == manager , "you are not manager");
        _;
    }

    modifier onlyVIP() {
        require(VIP[msg.sender] == true, "you are not our VIP customer");
        _;
    }

    function addVIP(address addr) public onlyManager {
        VIP[addr] = true;
    }

    function deposit() public payable onlyVIP {
        require(msg.value <= 0.05 ether, "Cannot deposit more than 0.05 ETH per transaction");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint _amount) public onlyVIP {
        require(address(this).balance <= maxETH, "Cannot withdraw more than 0.5 ETH per transaction");
        require(balances[msg.sender] >= _amount, "Not enough ether");
        balances[msg.sender] -= _amount;
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "Withdraw Failed!");
    }

    function contractBalance() public view returns (uint){
        return address(this).balance;
    }
}
```

Our goal is to lock the VIP users balance.

## Solution

In this case the vulnerability is pretty easy to spot. We should check if the amount we want to withdraw is bigger than maxETH but insteas we are checking if the balance of our contract is bigger than that. That results in the case, that if the balance of our contract ever goes above 0.5 eth, noone is able to withdraw anything anymore.

We should intentionally be protected against this by setting the deposit function to VIPOnly. nevertheless we can force feed solidity contracts using selfdestruct. I just used a simple template contract for force feeding:

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Forced{
    constructor () public payable {
        selfdestruct(0x570F2d712F9247d8eeaC3bf9ef1300b1b29cF480);
    }
}
```

After this we are not able to withdraw any money anymore
