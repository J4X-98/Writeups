# Challenge 02 : Dive into real life stuff - Blockchain && Challenge 03 : You have to be kidding me… - Blockchain && Challenge 04 : Now this is real life - Blockchain

This is a writeup for 3 challenges as they all were solved the same way.

## Challenge
We were provided token contracts for the challenges 02 and 03 and no contract for challenge 04. In addition a uniswapv2 router & factory were deployed, as well as the 2nd token WMEL. The 2 tokens were deployed as a pair on the router. The goal was to bring the WMEL liquidity to less than 0.5. All the contracts can be found in the src folder.

## Solution

My solution was probably unintented. The developers "forgot" to restrict the transferFrom() function in the WMEL token:

```
function transferFrom(address src, address dst, uint wad)
public
returns (bool)
{
    require(balanceOf[src] >= wad);
    if (!(balanceOf[src] >= wad))
    {
        revert();
    }

    if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
        // require(allowance[src][msg.sender] >= wad);
        allowance[src][msg.sender] -= wad;
    }

    balanceOf[src] -= wad;
    balanceOf[dst] += wad;

    Transfer(src, dst, wad);

    return true;
}
```

So you could just retrieve the address of the pair from the factory using getaPair() and the transfer all its WMEL liquidity to yourself, and the run sync to update the reserves. This worked for all 3 chals and yielded the flags:

Chal02: Hero{Th1s_1_w4s_3z_bro}
Chal03: Hero{H0w_L0ng_D1d_1t_T4k3_U_?..lmao}
Chal04: Hero{S0_Ur_4_r3AL_hUnT3r_WP_YMI!!!}