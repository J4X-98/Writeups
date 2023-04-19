// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract Donate {
    event t1(bytes _sig);
    address payable public keeper;
    address public owner;
    event newDonate(address indexed, uint amount);

    modifier onlyOwner() {
        require(
            msg.sender == owner || msg.sender == address(this),
            "You are not Owner"
        );
        _;
    }

    constructor(address _keeper) {
        keeper = payable(_keeper);
        owner = msg.sender;
    }

    function pay() external payable {
        keeper.transfer(msg.value);
        emit newDonate(msg.sender, msg.value);
    }

    function changeKeeper(address _newKeeper) external onlyOwner {
        keeper = payable(_newKeeper);
    }

    function secretFunction(string memory f) external {
        require(
            keccak256(bytes(f)) !=
                0x097798381ee91bee7e3420f37298fe723a9eedeade5440d4b2b5ca3192da2428,
            "invalid"
        );
        (bool success, ) = address(this).call(
            abi.encodeWithSignature(f, msg.sender)
        );
        require(success, "call fail");
    }

    function keeperCheck() external view returns (bool) {
        return (msg.sender == keeper);
    }
}