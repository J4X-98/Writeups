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