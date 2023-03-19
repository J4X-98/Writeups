// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// The following contract is vulnerable on purpose: DO NOT COPY AND USE IT ON MAINNET!
contract FilesManager is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    address public owner;
    string public ownerName;

    constructor(string memory _name, address _owner) ERC721("Files", "FLS") {
        ownerName = _name;
        owner = _owner;
    }

    function mintNewToken(string memory metadataUri) public {
        require(msg.sender == owner);
        tokenIds.increment();
        uint256 newId = tokenIds.current();
        _mint(owner, newId);
        _setTokenURI(newId, metadataUri);
    }
}