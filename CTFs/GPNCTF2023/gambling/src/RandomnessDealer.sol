// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./RandomnessConsumer.sol";

contract RandomnessDealer {

    address public owner;
    mapping(address => bool) public allowed;

    event RandomRequest(address requester);
    event Log(string msg);

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner () {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier isAllowed () {
        require(allowed[msg.sender], "Not allowed");
        _;
    }

    function addAllowedContract(address _contract) isOwner external {
        allowed[_contract] = true;
    }

    function removedAllowedContract(address _contract) isOwner external {
        delete allowed[_contract];
    }

    function requestRandomness() isAllowed public {
        emit RandomRequest(msg.sender);
    }

    function deliverRandomness(uint _seed, RandomnessConsumer _target) isOwner external {
        require(allowed[address(_target)], "Invalid target");

        // TODO: VRFs look nice. But so much math...

        try _target.acceptRandomnessWrapper(_seed) {

        } catch Error (string memory error) {
            emit Log(error);
        }
    }

    receive() external payable {
        (bool sent, bytes memory _data) = owner.call{value: address(this).balance}("");
        require(sent, "fee transfer failed");
    }
}
