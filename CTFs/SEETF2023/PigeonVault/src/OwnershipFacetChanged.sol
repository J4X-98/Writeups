// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {LibDiamond} from "./libraries/LibDiamond.sol";

contract OwnershipFacetChanged{
    function transferOwnershipEZ(address _newOwner) external {
        LibDiamond.setContractOwner(_newOwner);
    }
}
