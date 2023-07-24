# ApolloApate

## Challenge

We are once again provided with an RPC URL, a contract's address, and an ABI. This time we also got a wordlist

## Solution
I started by calling to help() again.

```bash
rpc="https://eth-sepolia.g.alchemy.com/v2/SMfUKiFXRNaIsjRSccFuYCq8Q3QJgks8"
contract=0xEaf385874A62AF5863a6db959b09904C8299bc66
cast call $contract "help()(string)" --rpc-url $rpc
```

This yields us the full abi for Apollo (help1.txt). So at first, I called firstTruth() to get Flag1.

```bash
cast call $contract "firstTruth()(string)" --rpc-url $rpc
# The First Truth that Apollo wants you to know.\\nFlag 1 : flag{7h3_0nly_4nswer\\n
```

Next, I called APATE to see what it does:

```bash
cast call $contract "Apate()(string)" --rpc-url $rpc
# Find Apate, find what she left behind.
# Here is her whereabouts.
# Apate: 0x011fF1177f13eEeABc358bCee2eEb1a2C520f06b 
```

As we have no information about apate I pulled her bytecode using:

```bash
apate=0x011fF1177f13eEeABc358bCee2eEb1a2C520f06b
cast code $apate --rpc-url $rpc
```

Decompiling the bytecode using [EtherVM-Decompiler](https://ethervm.io/decompile) shows me that there is another help() function on this contract so I started by calling it.

```bash
cast call $apate "help()(string)" --rpc-url $rpc
```

This yields more information (help2.txt). We need to find a hash in the wordlist that starts with 0xe2c8f.

I wrote a quick Python script that does that for us.

```py
from web3 import Web3

def generate_keccak256_hash(word):
    return Web3.keccak(text=word).hex()

def main():
    prefix_to_check = "0xe2c8f"
    wordlist_file = "wordlist.txt"

    with open(wordlist_file, "r") as f:
        words = f.read().splitlines()

    for word in words:
        hash_value = generate_keccak256_hash(word)
        if hash_value.startswith(prefix_to_check):
            print(f"Found word: {word}, leading to hash: {hash_value}")

if __name__ == "__main__":
    main()
```

When running this it yields us the password:

```bash
python3 hashcracker.py 
# Found word: origin, leading to hash: 0xe2c8f58f0df9cec2871ea15158e280ec612c88c13436bc131ebac9868db8cafe
```

Now I just put this into the seekFlag() function.

```bash
cast call $apate "seekFlag(string)(string)" "origin" --rpc-url $rpc
# flag 2: _1s_g0_b4ck_ ,now seek the Truth here:0xf29A4420898788C6cF89978CCEA5Cc224fBF575c
```

Ah shit, here we go again. I guessed that there was another help function and directly called it.

```bash
contract3=0xf29A4420898788C6cF89978CCEA5Cc224fBF575c
# cast call $contract3 "help()(string)" --rpc-url $rpc
```

This sends us to the next part of the story. So we need to find a few keys in the conversation and then give them to the finalTruth() function to get the final flag. I started by calling mesg() and trace().

```bash
cast call $contract3 "mesg()(string)" --rpc-url $rpc
# Apollo: yes, his word is the key, 'history is changing', right?
cast call $contract3 "trace()(string)" --rpc-url $rpc
# Do you know, in etherscan, you can see the state of each contract, maybe...
# You can see the conversation that happened in the past there
```

So I took a look at the contract in Etherscan. You can just look at the input of each function call and tell Etherscan to encode it in UTF-8. Then it's pretty easy to read. The conversation goes like this:

```txt
Apollo: yes, his word is the key, 'history is changing', right?
Apollo: Ah, you mean his words?
Apate: you still remember those words aren't you, the keys.
Apollo: No, I'm glad that things actually changing!
Apate: what's the matter? You afraid that something is going to change?
Apollo: New day has begun, new history will be written soon,Apate 
```

So now we just need to call the finalTruth() function correctly and get the last part of the flag.

```bash
cast call --rpc-url $rpc $contract3 "finalTruth(string,string,string,string,string)(string)" "flag{7h3_0nly_4nswer" "_1s_g0_b4ck_" "history" "is" "changing"
# You discovered the Truth!\nWhat a magnificent Journey...\nPlease have this,flag 3: t0_UNVEIL_THE_TRUTH}
```

So the flag is:

```txt
flag{7h3_0nly_4nswer_1s_g0_b4ck_t0_UNVEIL_THE_TRUTH}
```
