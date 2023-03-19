// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

// The following contract is vulnerable on purpose: DO NOT COPY AND USE IT ON MAINNET!
contract Gate {
    address public idManager;
    uint8[] private password;
    bool public gateLocked = true;

    constructor(address _idManager, uint8[] memory _password) {
        idManager = _idManager;
        password = _password;
    }

    function letMeIn(string memory _password) public returns(string memory) {
        (bool success, bytes memory result) = idManager.call(abi.encodeWithSignature("getIdentity(address)", msg.sender));
        require(success);
        string memory name = abi.decode(result, (string));
        bytes memory passbytes = bytes(_password);

        // user must be registered with a name
        require(bytes(name).length > 0 && passbytes.length == password.length);

        // user must be privileged
        idManager.call(abi.encodeWithSignature("requirePrivileges(address)", msg.sender));
        
        // user must know our secret password
        for (uint256 i = 0; i < password.length; i++) {
            require(password[i] == uint8(passbytes[i]));
        }

        gateLocked = false;
        return string.concat("Welcome, ", name);
    }
}