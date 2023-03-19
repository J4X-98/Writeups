// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

// The following contract is vulnerable on purpose: DO NOT COPY AND USE IT ON MAINNET!
contract IdentityManager {
    mapping(address => string) private identities;
    mapping(address => bool) private privileged;

    constructor() {
        privileged[msg.sender] = true;
    }

    function setMyIdentity(string memory name) public {
        identities[msg.sender] = name;
    }

    function setIdentityFor(address addr, string memory name) public {
        requirePrivileges(msg.sender);
        identities[addr] = name;
    }

    function setPrivileged(address addr) public {
        requirePrivileges(msg.sender);
        privileged[addr] = true;
    }

    function requirePrivileges(address addr) public view {
        require(privileged[addr]);
    }

    function getIdentity(address id) public view returns(string memory) {
        return identities[id];
    }
}