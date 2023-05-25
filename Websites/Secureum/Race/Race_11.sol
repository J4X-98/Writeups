// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Staking {

   using SafeERC20 for IERC20;

   bool internal _paused;
   address internal _operator;
   address internal _governance;
   address internal _token;
   uint256 internal _minDepositLockTime;

   mapping(address => uint256) _userBalances;
   mapping(address => uint256) _userLastDeposit;

   event Deposit(
       address indexed user,
       uint256 amount
   );

   event Withdraw(
       address indexed user,
       uint256 amount
   );

   constructor(address operator, address governance, address token, uint256 minDepositLockTime) {
       _operator = operator;
       _governance = governance;
       _token = token;
       _minDepositLockTime = minDepositLockTime;
   }

   function depositFor(address user, uint256 amount) external {
       _userBalances[user] += amount;
       _userLastDeposit[user] = block.timestamp;

       IERC20(_token).safeTransferFrom(user, address(this), amount);

       emit Deposit(msg.sender, amount);
   }

   function withdraw(uint256 amount) external {
       require(!_paused, 'paused');
       require(block.timestamp >= _userLastDeposit[msg.sender] + _minDepositLockTime, 'too early');

       IERC20(_token).safeTransferFrom(address(this), msg.sender, amount);

       if (_userBalances[msg.sender] >= amount) {
           _userBalances[msg.sender] -= amount;
       } else {
           _userBalances[msg.sender] = 0;
       }

       emit Withdraw(msg.sender, amount);
   }

   function pause() external {
       // operator or gov
       require(msg.sender == _operator && msg.sender == _governance, 'unauthorized');

       _paused = true;
   }

   function unpause() external {
       // only gov
       require(msg.sender == _governance, 'unauthorized');

       _paused = false;
   }

   function changeGovernance(address governance) external {
       _governance = governance;
   }
}