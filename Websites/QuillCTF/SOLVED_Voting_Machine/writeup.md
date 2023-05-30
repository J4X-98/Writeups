# Voting Machine
## Challenge

We are provided with the smart contract for a voting machine:

```solidity
pragma solidity 0.8.12;

import "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract VoteToken is ERC20("Vote Token", "vToken") {

    address public owner;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
        _moveDelegates(_delegates[_from], address(0), _amount);
    }


    mapping(address => address) internal _delegates;

    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }


    function _moveDelegates(address from, address to, uint256 amount) internal {
        if (from != to && amount > 0) {
            if (from != address(0)) {
                uint32 fromNum = numCheckpoints[from];
                uint256 fromOld = fromNum > 0 ? checkpoints[from][fromNum - 1].votes : 0;
                uint256 fromNew = fromOld - amount;
                _writeCheckpoint(from, fromNum, fromOld, fromNew);
            }

            if (to != address(0)) {
                uint32 toNum = numCheckpoints[to];
                uint256 toOld = toNum > 0 ? checkpoints[to][toNum - 1].votes : 0;
                uint256 toNew = toOld + amount;
                _writeCheckpoint(to, toNum, toOld, toNew);
            }
        }
    }

    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;
    mapping(address => uint32) public numCheckpoints;

    function delegates(address _addr) external view returns (address) {
        return _delegates[_addr];
    }

    function delegate(address _addr) external {
        return _delegate(msg.sender, _addr);
    }

    function getVotes(address _addr) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[_addr];
        return nCheckpoints > 0 ? checkpoints[_addr][nCheckpoints - 1].votes : 0;
    }

    function _delegate(address _addr, address delegatee) internal {
        address currentDelegate = _delegates[_addr];
        uint256 _addrBalance = balanceOf(_addr);
        _delegates[_addr] = delegatee;
        _moveDelegates(currentDelegate, delegatee, _addrBalance);
    }


    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint32 blockNumber = uint32(block.number);

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }
    }
}
```

Our goal is to accumulate at least 3000 votes in your hacker address. You don’t have any tokens in your wallet.

After trying all attempts and failing, you decided to perform a phishing attack and you successfully obtained the private keys from three users: Alice, Bob, and Carl.

Fortunately, Alice had 1000 vTokens, but Bob and Carl don’t have any tokens in their accounts. (see foundry setUp)

Now that you have access to the private keys of Alice, Bob, and Carl's accounts. So, try again. 

## Solution

The contract is structured super confusing. I first restructured and simplified it (V2 & V3). There is pretty much only one function we see that we can call that changes something in the contract (delegate). I'm emphasizing we can see. As the contract is derived from ERC20 it still includes all the ERC20 functions that were not overwritten. The real vulnerability is in the contract not decreasing your ammount of vToken after you voted/delegated. As we have 1000 token and 3 private keys (besides our hacker) we can just share the 1000 tokens and make each of the 3 others vote for the hacker and in the end send our token to him. The code for this can be found in the POC.
