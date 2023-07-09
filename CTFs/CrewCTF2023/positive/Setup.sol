pragma solidity =0.7.6;

import "./Positive.sol";

contract Setup {
    Positive public immutable TARGET;

    constructor() payable {
        TARGET = new Positive(); 
    }

    function isSolved() public view returns (bool) {
        return TARGET.solved();
    }
}

//priv_key = 0x218ada2e8d782200e170d5da9fbf7328741a7fcd606b58ca58b8af6257d4a232

// get address
// cast call 0xC8E218d36D255146E84F5d2b61045c08A26479E1 "TARGET()(address)" --rpc-url http://146.148.125.86:60083/42d638c7-b3ac-40d3-a9c3-54e33aa5cb43
// Positive is at 0x3e3fe68764FC9CE47d53b81EDAF9F766dd06D301






//check if solved
// cast call 0x3e3fe68764FC9CE47d53b81EDAF9F766dd06D301 "solved()(bool)" --rpc-url http://146.148.125.86:60083/42d638c7-b3ac-40d3-a9c3-54e33aa5cb43

