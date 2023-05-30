// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// The following contract is vulnerable on purpose: DO NOT COPY AND USE IT ON MAINNET!
contract Diamond is ERC20("Diamond", "DMD") {
    address private manager;
    address private extension;
    mapping(address => bool) private redeemers;
    uint256 private bonusRedeemsLeft = 5;
    uint256 private constant diamond = 10 ** 18; // 18 is the default decimals number

    constructor() {
        manager = msg.sender;
        _mint(address(this), 1000 * diamond);
    }

    function recovery(address newManager) public {
        require(tx.origin == manager);
        manager = newManager;
    }

    function getFirstRedeemerBonus() public {
        require(bonusRedeemsLeft > 0);
        require(redeemers[msg.sender] == false);
        bonusRedeemsLeft -= 1;
        redeemers[msg.sender] = true;
        bool success = this.transfer(msg.sender, 5 * diamond);
        require(success);
    }

    function setExtension(address newExtension) public {
        require(msg.sender == manager);
        extension = newExtension;
    }

    function callExtension(bytes memory _data) public {
        (bool success, ) = extension.delegatecall(_data);
        require(success);
    }
}