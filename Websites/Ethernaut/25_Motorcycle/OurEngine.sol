// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract OurEngine {

    function kill() public
    {
        selfdestruct(payable(0x2C17A5f47FF94Be930E74483BDa8FE0D3616AA1E));
    }
}