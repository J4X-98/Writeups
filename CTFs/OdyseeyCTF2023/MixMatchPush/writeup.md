# MixMatchPush

## Challenge

We only get the RPC URL, an address, and part of an ABI. Besides that, we don't get any information.

## Solution

I started by calling the help function, which was mentioned in the abi provided:

```bash
rpc="https://eth-sepolia.g.alchemy.com/v2/SMfUKiFXRNaIsjRSccFuYCq8Q3QJgks8"
contract=0x97891c560284eAf12175d950bf65Dba071e6a06F

cast call $contract "help()(string)" --rpc-url $rpc
# These are the function required to finish this task:
# getFlag -> to get your "flag"
# getMapping -> to see the "mapping"
# Encrypt -> to see what's encryption result of your inputted string
```

So there is a Encrypt function and we can also get the flag. So let's first get the flag:

```bash
cast call $contract "getFlag()(string)" --rpc-url $rpc
# peyx.r5-70-y-D7fne2-ZVan59-6pg2k-6UU-mpw25=
```

This seems somewhat encrypted. So my next guess was to check out the Encrypt function. When trying to call the function it kept reverting. So I decided to get the bytecode like this:

```bash
cast code $contract --rpc-url $rpc
```

When decompiling it using the [EtherVM-Decompiler](https://ethervm.io/decompile) it showed me that the function is called encrypt() and not Encrypt(). As the selector is based on the hash of the function name this results in me always calling the wrong selector.

So the next step was to call encrypt with some random values. I quickly realized that all that encrypt did was take each character and flip it for another one. This always being the same so you should easily be able to create yourself the mapping if you have an oracle. I called the Oracle a few times to get all information I needed.

```bash
cast call $contract "encrypt(string)(string)" "ABCDEFGHIJKLMNOPQRSTUVWXYZ"  --rpc-url $rpc
# XPZQRCAMSOLUNTJWBVDFYKIHGE
cast call $contract "encrypt(string)(string)" "abcdefghijklmnopqrstuvwxyz"  --rpc-url $rpc
# ymqwzpxsrtlefbcnjkvgidhuao
cast call $contract "encrypt(string)(string)" ",;.:_-{}"  --rpc-url $rpc
# ?+,_-!.=
cast call $contract "encrypt(string)(string)" "1234567890"  --rpc-url $rpc
# 7426035189
```

This yielded me the following 4 mappings where I could check and reverse the encryption:
```txt
Bold Letters:
ABCDEFGHIJKLMNOPQRSTUVWXYZ
XPZQRCAMSOLUNTJWBVDFYKIHGE

Small_letters:
abcdefghijklmnopqrstuvwxyz
ymqwzpxsrtlefbcnjkvgidhuao

Special Characters:
,;.:_-{}
?+,_-!.=

Numbers:
1234567890
7426035189
```

After going backward by hand I got the flag:

```txt
peyx.r5-70-y-D7fne2-ZVan59-6pg2k-6UU-mpw25=
flag{i7_15_a_S1mpl3_CRyp70_4ft3r_4LL_bfd37}
```