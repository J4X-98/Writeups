// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "forge-std/Test.sol";

contract EQ is Test {
    address isNumbersEQContract;
    bytes1[] badOpcodes;

    function setUp() public {
        badOpcodes.push(hex"01");
        badOpcodes.push(hex"02"); // MUL
        badOpcodes.push(hex"03"); // SUB
        badOpcodes.push(hex"04"); // DIV
        badOpcodes.push(hex"05"); // SDIV
        badOpcodes.push(hex"06"); // MOD
        badOpcodes.push(hex"07"); // SMOD
        badOpcodes.push(hex"08"); // ADDMOD
        badOpcodes.push(hex"09"); // MULLMOD
        badOpcodes.push(hex"18"); // XOR
        badOpcodes.push(hex"10"); // LT
        badOpcodes.push(hex"11"); // GT
        badOpcodes.push(hex"12"); // SLT
        badOpcodes.push(hex"13"); // SGT
        badOpcodes.push(hex"14"); // EQ
        badOpcodes.push(hex"f0"); // create
        badOpcodes.push(hex"f5"); // create2
        badOpcodes.push(hex"19"); // NOT
        badOpcodes.push(hex"1b"); // SHL
        badOpcodes.push(hex"1c"); // SHR
        badOpcodes.push(hex"1d"); // SAR
        vm.createSelectFork(
            "https://eth-mainnet.g.alchemy.com/v2/..."
        );
        address isNumbersEQContractTemp;
        // solution - your bytecode
        bytes
            memory bytecode = hex"...";
        //
        require(bytecode.length < 40, "try harder!");
        for (uint i; i < bytecode.length; i++) {
            for (uint a; a < badOpcodes.length; a++) {
                if (bytecode[i] == badOpcodes[a]) revert();
            }
        }

        assembly {
            isNumbersEQContractTemp := create(
                0,
                add(bytecode, 0x20),
                mload(bytecode)
            )
            if iszero(extcodesize(isNumbersEQContractTemp)) {
                revert(0, 0)
            }
        }
        isNumbersEQContract = isNumbersEQContractTemp;
    }

    // fuzzing test
    function test_isNumbersEq(uint8 a, uint8 b) public {
        (bool success, bytes memory data) = isNumbersEQContract.call{value: 4}(
            abi.encodeWithSignature("isEq(uint256, uint256)", a, b)
        );
        require(success, "!success");
        uint result = abi.decode(data, (uint));
        a == b ? assert(result == 1) : assert(result != 1);

        // additional tests
        // 1 - equal numbers
        (, data) = isNumbersEQContract.call{value: 4}(
            abi.encodeWithSignature("isEq(uint256, uint256)", 57204, 57204)
        );
        require(abi.decode(data, (uint)) == 1, "1 test fail");
        // 2 - different numbers
        (, data) = isNumbersEQContract.call{value: 4}(
            abi.encodeWithSignature("isEq(uint256, uint256)", 0, 3568)
        );
        require(abi.decode(data, (uint)) != 1, "2 test fail");
    }
}