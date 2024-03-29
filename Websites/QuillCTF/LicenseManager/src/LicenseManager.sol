// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/**
 * @title LicenseManager CTF
 * @dev We are looking at a Smart Contract called LicenseManager for managing licenses that cost 1 ether. As attackers, we only have 0.01 ether instead, and our first goal is to get the license anyway. Also, find at least two ways to collect the ethers in the contract before the owner notices. 
*/
contract LicenseManager {
    address private owner;
    address[] private licensed;
    mapping(address => bool) private licenseOwners;
    
    constructor() {
        owner = msg.sender;
    }
    
    function buyLicense() public payable {
        require(msg.value == 1 ether || msg.sender == owner, "Send 1 ether to buy a license. Owner can ask for free");
        licensed.push(msg.sender);
        licenseOwners[msg.sender] = true;
    }
    
    function checkLicense() public view returns(bool) {
        return licenseOwners[msg.sender];
    }
    
    function winLicense() public payable returns(bool) {
        require(msg.value >= 0.01 ether && msg.value <= 0.5 ether, "Send between 0.01 and 0.5 ether to try your luck");
        uint maxThreshold = uint((msg.value / 1e16));
        uint algorithm = uint(keccak256(abi.encodePacked(uint256(msg.value), msg.sender, uint(1337), blockhash(block.number - 1))));
        uint pickedNumber =  algorithm % 100;
        if (pickedNumber < maxThreshold) {
            licenseOwners[msg.sender] = true;
        }
        return licenseOwners[msg.sender];
    }

    function refundLicense() public {
        require(licenseOwners[msg.sender] == true, "You are not a licensed user");

        for (uint i = 0; i < licensed.length; i++) {
            if (licensed[i] == msg.sender) {
                licensed[i] = licensed[licensed.length-1];
                licensed.pop();
                break;
            }
        }
        (bool success, ) = msg.sender.call{value: 1 ether}("");
        require(success, "Transfer failed.");

        licenseOwners[msg.sender] = false;

    }
    
    function collect() public {
        require(msg.sender == owner, "Only the owner can collect.");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}