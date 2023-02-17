
# Proxy (0x717F6DB06A4a13Ed35E69fB48C9a31aDfa6D1F2f):
- delegatecall could overwrite vairables, changing maxbalance while in delegatecall could overwrite admin
- not Whitelisted
- is using upgradeTo not _upgradeTo

# Wallet (0xd3cd6083e732BCEe37401FDAB110FA095CA7b599):
- require in setMaxBalance alarms if we go through delegate as it would check the balance of the Proxy which is 0.001Eth
- via setMaxBalance we could also overwrite the owner of the wallet, by first setting max balance to 0 and then using the init function
- we could also go via the proxy, call the wallet and overwrite the admin of the proxy using setMaxBalance
- money inside the Proxy is owned by the Level

Owner = Level adress
MaxBalance = Level Adress (Probably because of the proxy overwriting using pending admin)

https://medium.com/@jeremythen16/solidity-delegatecall-usage-and-pitfalls-5c37eaa5bd5d

# Possible Attack paths:

## Their Proxy -> Wallet.setMaxBalance() -> Overwrite Admin

Problem is the proxy has a balance which will cause the require to fail

## Attack plan: 
1. Create our own contract where the 2nd slot is 0
2. Delegate to the wallet for init
3. Wallet checks out 2nd slot instead of its own and lets us call init
4. Call .whitelist() and add yourself

5. Proxy delegate to setMaxBalance -> overwrite admin using the function

5. Call to .multicall() -> multicall delegate to proxy -> Proxy overwrite maxBalance using proposeNewAdmin
6. Set Max Balance to 0 without a delegate
7. Become owner of PuzzleWallet using init



Attack
1. Maxbalance is still 0 so we can overwrite owner with ourself
2. Whitelist ourself
3. Set Maxbalance to ourself
4. propose ourself as new admin
4. Proxy, then multicall to approvenewadmin