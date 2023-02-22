
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

Attack
1. Add us to the pendingAdmin which the wallet will see as the owner
2. Whitelist ourself
3. Do a nested multicall so we can deposit 2x (could also be 10000x)
4. Drain the proxy.
4. Overwrite the owner with ourself