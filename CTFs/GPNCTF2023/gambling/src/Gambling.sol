// SPDX-License-Identifier: UNLICENSED

// deployed at https://sepolia.etherscan.io/address/0x2f51e462522AF7b4bcc0CCF6c9368D3B19267bfe

pragma solidity ^0.8.9;

import "./RandomnessConsumer.sol";

contract Gambling is RandomnessConsumer {
    struct Guess {
        uint number;
        uint block;
    }

    mapping(address => uint) public streak;
    mapping(address => Guess) public guesses;

    Guess public seed;
    uint public lastRandomRequest;

    event DeliverFlag(string ip, uint port);
    event Win(address winner);
    event Fail(address sender);

    constructor(RandomnessDealer _dealer) {
        randomDealer = _dealer;

        streak[msg.sender] = 5;
        seed.block = 1;
    }

    function enter(uint _number) external payable {
        require(msg.value > 0.001 ether, "give moneyz");

        if (guesses[msg.sender].block > 0 && guesses[msg.sender].block < seed.block) {
            // missed a guess
            streak[msg.sender] = 0;
        }

        guesses[msg.sender] = Guess(_number, seed.block);

        if (block.number > lastRandomRequest) {
            randomDealer.requestRandomness();
            lastRandomRequest = block.number;
        }

        // we need to pay this randomness guy
        (bool sent, bytes memory _data) = address(randomDealer).call{value: address(this).balance}("");
        require(sent, "fee transfer failed");
    }

    function claim() external returns (bool) {
        require(guesses[msg.sender].block != 0, "bet not found");
        require(guesses[msg.sender].block < seed.block, "too old");

        uint userSeed = uint(sha256(abi.encodePacked(seed.number, msg.sender, seed.block)));
        uint ticket = userSeed % 100000000;

        if (guesses[msg.sender].number == ticket) {
            streak[msg.sender] += 1;
            delete guesses[msg.sender];

            emit Win(msg.sender);
            return true;
        }

        streak[msg.sender] = 0;
        delete guesses[msg.sender];
        emit Fail(msg.sender);
        return false;
    }

    function flag(string memory ip, uint port) external {
        require(streak[msg.sender] >= 5, "no flag for you");

        emit DeliverFlag(ip, port);
    }

    function acceptRandomness(uint _number) internal override {
        require(msg.sender == address(randomDealer));

        seed = Guess(_number, block.number);
    }
}
