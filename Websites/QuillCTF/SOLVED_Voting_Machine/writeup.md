# Voting Machine
## Challenge

We are provided with the smart contract for a voting amchine:


Our goal is to accumulate at least 3000 votes in your hacker address. You don’t have any tokens in your wallet.

After trying all attempts and failing, you decided to perform a phishing attack and you successfully obtained the private keys from three users: Alice, Bob, and Carl.

Fortunately, Alice had 1000 vTokens, but Bob and Carl don’t have any tokens in their accounts. (see foundry setUp)

Now that you have access to the private keys of Alice, Bob, and Carl's accounts. So, try again. 

## Solution

The contract is structured super confusing. I first restructured and simplified it (V2 & V3). There is pretty much only one function we see that we can call that changes something in the contract (delegate). I'm emphasizing we can see. As the contract is derived from ERC20 it still includes all the ERC20 functions that were not overwritten. The real vulnerability is in the contract not decreasing your ammount of vToken after you voted/delegated. As we have 1000 token and 3 private keys (besides our hacker) we can just share the 1000 tokens and make each of the 3 others vote for the hacker and in the end send our token to him. The code for this can be found in the POC.
