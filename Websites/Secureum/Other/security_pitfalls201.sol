pragma solidity 0.7.0;

contract InSecureumToken {

mapping(address => uint) private balances;

uint public decimals = 10**18; // decimals of the token
uint public totalSupply; // total supply
uint MAX_SUPPLY = 100 ether; // Maximum total supply

event Mint(address indexed destination, uint amount);

function transfer(address to, uint amount) public {
    // save the balance in local variables
    // so that we can re-use them multiple times
    // without paying for SLOAD on every access
    uint balance_from = balances[msg.sender];
    uint balance_to = balances[to];
    require(balance_from >= amount);
    balances[msg.sender] = balance_from - amount;
    balances[to] = safeAdd(balance_to, amount);
}

/// @notice Allow users to buy token. 1 ether = 10 tokens
/// @dev Users can send more ether than token to be bought, to donate a fee to the protocol team
function buy(uint desired_tokens) public payable {
    // Check if enough ether has been sent
    uint required_wei_sent = (desired_tokens / 10) * decimals;
    require(msg.value >= required_wei_sent);

    // Mint the tokens
    totalSupply = safeAdd(totalSupply, desired_tokens);
    balances[msg.sender] = safeAdd(balances[msg.sender], desired_tokens);
    emit Mint(msg.sender, desired_tokens);
}

/// @notice Add two values. Revert if overflow
function safeAdd(uint a, uint b) pure internal returns(uint) {
    if (a + b < a) {
        revert();
    }
    return a + b;
}
}