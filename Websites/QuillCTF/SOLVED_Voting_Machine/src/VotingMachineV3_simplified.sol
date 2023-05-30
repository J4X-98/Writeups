pragma solidity 0.8.12;

import "@openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract VoteToken is ERC20("Vote Token", "vToken") {

    address public owner;
    mapping(address => address) internal _delegates;
    mapping(address => uint32) public numCheckpoints;
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    //ERC20 functions
    //------------------------------------------------------------------------------------------------------------------
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }

    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
        _moveDelegates(_delegates[_from], address(0), _amount);
    }
    //------------------------------------------------------------------------------------------------------------------

    //Accessible function
    //------------------------------------------------------------------------------------------------------------------
    function delegate(address _addr) external {        
        address currentDelegate = _delegates[msg.sender];
        uint256 _addrBalance = balanceOf(msgsender);
        _delegates[msg.sender] = _addr;

        if (currentDelegate != _addr && amount > 0) {
            if (currentDelegate != address(0)) {
                uint32 fromNum = numCheckpoints[currentDelegate];
                uint256 fromOld = fromNum > 0 ? checkpoints[currentDelegate][fromNum - 1].votes : 0;
                uint256 fromNew = fromOld - amount;

                _writeCheckpoint(currentDelegate, fromNum, fromOld, fromNew);
            }

            if (_addr != address(0)) {
                uint32 toNum = numCheckpoints[_addr];
                uint256 toOld = toNum > 0 ? checkpoints[_addr][toNum - 1].votes : 0;
                uint256 toNew = toOld + amount;

                _writeCheckpoint(_addr, toNum, toOld, toNew);
            }
        }
    }
    
    function delegates(address _addr) external view returns (address) {
        return _delegates[_addr];
    }

    function getVotes(address _addr) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[_addr];
        return nCheckpoints > 0 ? checkpoints[_addr][nCheckpoints - 1].votes : 0;
    }
    //------------------------------------------------------------------------------------------------------------------


    //Internal functions
    //------------------------------------------------------------------------------------------------------------------

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint256 oldVotes, uint256 newVotes) internal {
        uint32 blockNumber = uint32(block.number);

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }
    }
    //------------------------------------------------------------------------------------------------------------------
}