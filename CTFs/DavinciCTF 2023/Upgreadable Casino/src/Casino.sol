// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

contract Casino {
    uint256 maxFreeTokens = 10;

    // Keep track of the tokens spent at each game
    uint64 roulette = 0;
    uint64 slotMachine = 0;
    uint64 blackjack = 0;
    uint64 poker = 0;

    address admin = 0x5aB8C62A01b00f57f6C35c58fFe7B64777749159;
    mapping(address => uint256) balances;
    mapping(address => uint256) lastFreeTokenRequest;


    function changeMaxFreeTokens(uint256 newValue) external
    {
        require(msg.sender == admin, "Only admin can change the number of free tokens you can get");
        maxFreeTokens = newValue;
    }

    function requestFreeTokens(uint256 numberOfTokensRequested) external {
        require(numberOfTokensRequested <= maxFreeTokens, "You can't request that much free tokens");

        require(block.number > lastFreeTokenRequest[msg.sender] + 2,
        "Wait a few more blocks before collecting free tokens");

        lastFreeTokenRequest[msg.sender] = block.number;

        balances[msg.sender] += numberOfTokensRequested;
    }

    function playTokens(uint64 tokensForRoulette, uint64 tokensForSlotMachine, uint64 tokensForBlackjack, uint64 tokensForPoker) external
    {
        require(tokensForRoulette + tokensForSlotMachine + tokensForBlackjack + tokensForPoker <= balances[msg.sender],
        "You don't have enough tokens to play");

        // Increase the analytics variables
        roulette += tokensForRoulette;
        slotMachine += tokensForSlotMachine;
        blackjack += tokensForBlackjack;
        poker += tokensForPoker;

        balances[msg.sender] -= tokensForRoulette + tokensForSlotMachine + tokensForBlackjack + tokensForPoker;

        uint256 earnedTokens = 0;

        // Play the tokens at the chosen games

        // Roulette
        earnedTokens += tokensForRoulette*2*(randMod(3) == 0 ? 1 : 0);
        
        // Slot
        earnedTokens += tokensForSlotMachine * 500 * (randMod(1000) == 0 ? 1 : 0);

        // Blackjack
        earnedTokens += tokensForBlackjack * 15 * (randMod(21) == 0 ? 1 : 0);

        // Poker
        earnedTokens += tokensForPoker * 10000 * (randMod(15000) == 0 ? 1 : 0);

        balances[msg.sender] += earnedTokens;
    }

    // Initializing the state variable
    uint randNonce = 0;
 
    // Defining a function to generate
    // a random number
    function randMod(uint _modulus) internal returns(uint)
    {
        // increase nonce
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
    }

    function getBalance(address user) external view returns(uint256){
        return balances[user];
    }

    function buyTokens() payable external {
        // deposit sizes are restricted to 1 ether
        require(msg.value == 1 ether);

        balances[msg.sender] += 10000 ;
    }
}