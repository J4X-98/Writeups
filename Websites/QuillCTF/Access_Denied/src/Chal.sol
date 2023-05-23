// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract access_denied {
    string private data; 
    address admin;

    constructor(string memory _data) {
        data = _data;
        admin = msg.sender;
    }

    function isContract(address addr) public view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    modifier noEOA {
        require (msg.sender != tx.origin, "No-EOA allowed!");
        _;
    }

    modifier noContract {
        require (!isContract(msg.sender), "No-contract allowed either!");
        _;
    }

    function changeAdmin(address _addr) external noEOA noContract {
        _changeAdmin(_addr);
    }

    function _changeAdmin(address _addr) private {
        require(msg.sender==_addr);
        admin = _addr ;

    }
    
    function getflag() public view returns (string memory) {
        require(msg.sender == admin, "You are not admin yet!");
        return(data);
    }
}