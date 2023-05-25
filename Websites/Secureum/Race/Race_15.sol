// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";

contract SimpleDEX {
    uint64 public token_balance;
    uint256 public current_eth;
    IERC20 public token;
    uint8 public reentrancy_lock;
    address owner;
    uint256 public fees;
    uint256 public immutable fees_percentage = 10;

    modifier nonReentrant(){
        // Logic needs to be implemented    
        _; 
    }

    modifier onlyOwner(){
        require(tx.origin == owner, "Only owner permitted");
        _;
    }

    constructor(uint first_balance, address _token, address _owner) payable {
        require(_owner != address(0) , "No zero Address allowed");
        require(msg.value >= 100);
        token = IERC20(_token);
        bool token_success = token.transferFrom(msg.sender, address(this), first_balance);
        require (token_success, "couldn't transfer tokens");
        owner = _owner;
        token_balance = uint64(first_balance);
        current_eth = msg.value;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function getTokenBalance() public view returns(uint64 _token_balance) {
        _token_balance = token_balance;
    }

    function getCurrentEth() public view returns(uint256 _current_eth) {
        _current_eth = current_eth;
    }

    function getEthPrice() public view returns(uint) {
        return uint256(token_balance) / current_eth;
    }

    function claimFees() public onlyOwner {
        bool token_success =  token.transfer(msg.sender,fees);
        require(token_success, "couldn't transfer tokens");
        token_balance -= fees; 
        fees = 0;
    }

    function buyEth(uint amount) external nonReentrant {
        require(amount >= 10);
        uint ratio = getEthPrice();
        uint fee = (amount / 100) * fees_percentage;
        uint token_amount = ratio * (amount + fee);
        bool token_success = token.transferFrom(msg.sender, address(this), token_amount);
        current_eth -= amount;
        require(token_success, "couldn't transfer tokens");
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to transfer Eth");
        token_balance += uint64(token_amount);
        fees += ratio * fee; 
    }

    fallback() payable external {
        revert();
    }
}


contract SimpleDexProxy {
    function buyEth(address simpleDexAddr, uint amount) external {
        require(amount > 0, "Zero amount not allowed");
        (bool success, ) = (simpleDexAddr).call(abi.encodeWithSignature("buyEth(uint)", amount));
        require (success, "Failed");
    }
}


contract Seller {
    // Sells tokens to the msg.sender in exchange for eth, according to SimpleDex's getEthPrice() 
    function buyToken(SimpleDEX simpleDexAddr, uint token_amount) external payable {
        uint ratio = simpleDexAddr.getEthPrice();
        IERC20 token = simpleDexAddr.token(); 
        uint eth = token_amount / ratio;
        require(token_amount == ratio *eth); //only exact exchange 
        require(eth >= msg.value);
        token.transfer(msg.sender, token_amount);
    }
}