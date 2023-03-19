// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./FilesManager.sol";

// The following contract is vulnerable on purpose: DO NOT COPY AND USE IT ON MAINNET!
contract FilesManagerDeployer {
    function createNewFileManagerFor(string memory name) public returns(address) {
        return address(new FilesManager(name, msg.sender));
    }
}