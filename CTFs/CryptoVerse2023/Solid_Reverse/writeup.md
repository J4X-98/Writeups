# Solid Reverse - Reverse

## Challenge

We are presented with one Solidity contract:

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReverseMe {
    uint goal = 0x57e4e375661c72654c31645f78455d19;

    function magic1(uint x, uint n) public pure returns (uint) {
        // Something magic
        uint m = (1 << n) - 1;
        return x & m;
    }

    function magic2(uint x) public pure returns (uint) {
        // Something else magic
        uint i = 0;
        while ((x >>= 1) > 0) {
            i += 1;
        }
        return i;
    }

    function checkflag(bytes16 flag, bytes16 y) public view returns (bool) {
        return (uint128(flag) ^ uint128(y) == goal);
    }

    modifier checker(bytes16 key) {
        require(bytes8(key) == 0x3492800100670155, "Wrong key!");
        require(uint64(uint128(key)) == uint32(uint128(key)), "Wrong key!");
        require(magic1(uint128(key), 16) == 0x1964, "Wrong key!");
        require(magic2(uint64(uint128(key))) == 16, "Wrong key!");
        _;
    }

    function unlock(bytes16 key, bytes16 flag) public view checker(key) {
        // Main function
        require(checkflag(flag, key), "Flag is wrong!");
    }
}
```

Our goal is to find a key that fits the requires and xor'd to the goal yields us the flag.

## Solution

We in total have 4 requires which we can use to guess the key.

### require(bytes8(key) == 0x3492800100670155, "Wrong key!");

This is pretty easy, it just tells us that the first 8 bytes of our key have to be this.

So our current key is:

0x3492800100670155XXXXXXXXXXXXXXXX

### require(uint64(uint128(key)) == uint32(uint128(key)), "Wrong key!");

This is also pretty straight forward, we cast our 16 byte key to 8bytes and 4 bytes and want the results to be the same. This means that the bytes 7-4 need to be zero so it doesn't matter if we cast to 4 or 8 byte. Our key now is:

0x349280010067015500000000XXXXXXXX

### require(magic1(uint128(key), 16) == 0x1964, "Wrong key!");

Now we get to use the first magic function:

```
function magic1(uint x, uint n) public pure returns (uint) {
    // Something magic
    uint m = (1 << n) - 1;
    return x & m;
}
```

What this does for us is generate a value that is n bits long and all zeros, and then ands our x with it, which just results in the first n bits of x. This means that our last 2 bytes are 0x1964. Our key now is:

0x349280010067015500000000XXXX1964

### require(magic2(uint64(uint128(key))) == 16, "Wrong key!");

Now we use our second magic function:

```
function magic2(uint x) public pure returns (uint) {
    // Something else magic
    uint i = 0;
    while ((x >>= 1) > 0) {
        i += 1;
    }
    return i;
}
```
This just shifts our x by one to the left each step and increases i as long as x is not 0. As this should be 16, we are only using the last 8 bytes and the i starts counting after the first shift, this means what the 33rd bit is 1 and then there are only zeroes. This results in the final key:

0x34928001006701550000000000011964

### XOR

Now we just need to xor this to the goal and get the flag:

```
0x34928001006701550000000000011964
^
0x57e4e375661c72654c31645f78455d19
=
0x63766374667b73304c31645f7844447d
```

This yields us the flag: cvctf{s0L1d_xDD}
