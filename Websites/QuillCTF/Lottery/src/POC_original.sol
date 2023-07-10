// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract Factory {
    function dep(bytes memory _code) public payable returns (address x) {
        require(msg.value >= 10 ether);
       
        assembly {
            x := create(0, add(0x20, _code), mload(_code))
        }
        if (x == address(0)) payable(msg.sender).transfer(msg.value);
    }
}

contract Lottery is Test {
   
    Factory private factory;
    address attacker;

    function setUp() public {
        factory = new Factory();
        attacker = makeAddr("attacker");
    }

    function testLottery() public {
        vm.deal(attacker, 11 ether);
        vm.deal(0x0A1EB1b2d96a175608edEF666c171d351109d8AA, 200 ether);
        vm.startPrank(attacker);
       
        //Solution
       
        vm.stopPrank();
        assertGt(attacker.balance, 200 ether);
    }
}