
# True XOR

## Challenge

We get one contract:

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBoolGiver {
  function giveBool() external view returns (bool);
}

contract TrueXOR {
  function callMe(address target) external view returns (bool) {
    bool p = IBoolGiver(target).giveBool();
    bool q = IBoolGiver(target).giveBool();
    require((p && q) != (p || q), "bad bools");
    require(msg.sender == tx.origin, "bad sender");
    return true;
  }
}
```

Our goal is to succesfully call the callMe function without triggering a revert

## Solution

The goal is that our function returns true/ false on both calls, but not the same on both. First we have to implement the IBoolGiver Interface into our own contract, so we need a function giveBool() that is view and returns a bool. 

The view specification makes it harder for us, as we could otherwise just set a bool after the first call and then check for it in the second call and send false. 

I just used the gasleft() option to differ between the 2 calls. If you would want to do it the clean way you could run the call and debug how much gas is left after the 1st and 2nd attempt. I thought that i have a 50/50 chance that one is even and one is not even. To my luck that worked and saved me the time of reverse engineering. Following this you can see my exploit contract:

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Target.sol";

contract Attack is IBoolGiver{
    bool first_call;

    constructor()
    {
        first_call = true;
    }

    function giveBool() external view override returns (bool)
    {
        if (gasleft()%2 == 1)
        {
            return true;
        }
        else 
        {
            return false;
        }
    }
}
```


