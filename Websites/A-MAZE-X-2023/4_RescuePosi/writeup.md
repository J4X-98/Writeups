# RescuePosi

## Challenge

This challenge is once again focused on the create2 operator. We are provided with a standard ERC20 and 2 other contracts. Of those one is the template of a wallet that the company also used on the other chaín (not that interesting) and the deployment contract(mildly interesting). To keep it simple I just added the deployment contract as the others are not needed for the solution, the token has standard functionalities and the only interesting thing about the wallet is that you can use it to store/send ERC20 tokens if you are the owner. 

### Vaultfactory.sol

The VaultFactory has the interesting functionality that you can provide it with any bytecode and salt, and it will deploy it. It pretty much is a wrapper for a CREATE2 call.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title VaultFactory
 */
contract VaultFactory {
    // Events
    event Deployed(address indexed addr);

    /**
     * @notice The address of the deployed contract is emitted in the Deployed event
     * @dev Deploys a contract
     * @param code The bytecode of the contract to deploy
     * @param salt The salt to use for the deployment
     * @return addr The address of the deployed contract
     */
    function deploy(bytes memory code, uint256 salt) public returns (address addr) {
        assembly {
            addr := create2(     // Deploys a contract using create2.
                0,               // wei sent with current call
                add(code, 0x20), // Pointer to code, with skip the assembly prefix
                mload(code),     // Length of code
                salt             // The salt used
            )
            if iszero(extcodesize(addr)) { revert(0, 0) } // Check if contract deployed correctly, otherwise revert.
        }
        emit Deployed(addr);
    }

    /**
     * @notice This function is used to call the initialize function of the deployed contract
     * @dev Executes a call to a contract
     * @param addr The address of the contract to call
     * @param data The data to send to the contract
     */
    function callWallet(address addr, bytes memory data) public {
        assembly {
            let result := call(  // Performs a low level call to a contract
                gas(),           // Forward all gas to the call
                addr,            // The address of the contract to call
                0,               // wei passed to the call
                add(data, 0x20), // Pointer to data, with skip the assembly prefix
                mload(data),     // Length of data
                0,               // Pointer to output, we don't use it
                0                // Size of output, we don't use it
            )
            let size := returndatasize() // Get the size of the output
            let ptr := mload(0x40)       // Get a free memory pointer
            returndatacopy(ptr, 0, size) // Copy the output to the pointer
            switch result                 // Check the result:
            case 0 { revert(ptr, size) }  // If failed, revert with the output
            default { return(ptr, size) } // If success, return the output
        }
    }
}

```

Challenge Description:

Hello whitehat! We are so thankful for your answer to our cry for help! Time is running out... There is a huge amount of tokens sitting on an address that we can't access. We need your help to rescue them!

For context, we have to transfer a big big amount of these tokens to a very important organization before a deadline. Unfortunately, we made a typo in the destination address (plus we didn't check the checksummed version of the address) and now the tokens are stuck in an address that doesn't belong to anyone.

However, we noticed that the address where our funds are stuck is coincidentally the same address as one of the vaults we develop but in another EVM chain... The address of the vault is `0x70E194050d9c9c949b3061CC7cF89dF9c6782b7F`, which was deployed by our vault-factory. The EOA who triggered that deploy, `0x6F77cf861457C29aCAFB6c7340Aee8fbcE84dD08` belongs to an old employee that left the company a long time ago, and we don't have access to the corresponding private key... There is little information left about this employee, we don't even know if he is still alive. The only thing that we know is that he used to work with us in the past, that his birthday was in November and that he was a big fan of the `CREATE2` opcode. What a silly guy... 

Anyways, please whitehat make use of your skills to rescue the tokens and transfer them to the address of our organization!

📌 Extract the 1000 `POSI` tokens from the Vault.

📌 Transfer the rescued tokens to the address of the organization.

## Solution

As we know that the address is already a wallet on a different EVM chain we know that it must be one of the possible 2 to the power of 256  outcomes(dependent on the salt) outcomes of create2 with the wallet's bytecode. As we know the bytecode of the wallet contract, we can just brute force through CREATE2 to see which salt generates a wallet at the given address. In reality, this isn't doable, as 2 to the power of 256 computations on the EVM will never work. But in this case, it works as it seems that the person that generated their wallet there, picked a very simple salt. So I just implemented this in the foundry testcase and only needed 11 computations to find the address. Then I just used the wallet functions to send back all the money to the devs and the challenge is solved.

```solidity
//This is inefficient AF Don't try this at home kids
bool success = false;
uint256 saltyMcSaltface = 0;
address payable newWallet;

//Get the bytecode of the wallet template
bytes memory code = type(VaultWalletTemplate).creationCode;

//Generate new wallets until the address matches the unclaimed address
while (!success)
{
    newWallet = payable(FACTORY.deploy(code, saltyMcSaltface));
    success = newWallet == unclaimedAddress;
    saltyMcSaltface += 1;
}

//Initialize the wallet
VaultWalletTemplate walletWeWant = VaultWalletTemplate(newWallet);
walletWeWant.initialize(whitehat);

//Withdraw the funds to the devs
walletWeWant.withdrawERC20(address(POSI), 1000 ether, devs);
```