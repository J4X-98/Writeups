BAD:
    badOpcodes.push(hex"01"); // ADD
    badOpcodes.push(hex"02"); // MUL
    badOpcodes.push(hex"03"); // SUB
    badOpcodes.push(hex"04"); // DIV
    badOpcodes.push(hex"05"); // SDIV
    badOpcodes.push(hex"06"); // MOD
    badOpcodes.push(hex"07"); // SMOD
    badOpcodes.push(hex"08"); // ADDMOD
    badOpcodes.push(hex"09"); // MULLMOD
    badOpcodes.push(hex"10"); // LT
    badOpcodes.push(hex"11"); // GT
    badOpcodes.push(hex"12"); // SLT
    badOpcodes.push(hex"13"); // SGT
    badOpcodes.push(hex"14"); // EQ

    badOpcodes.push(hex"18"); // XOR
    badOpcodes.push(hex"19"); // NOT

    badOpcodes.push(hex"1b"); // SHL
    badOpcodes.push(hex"1c"); // SHR
    badOpcodes.push(hex"1d"); // SAR
    badOpcodes.push(hex"f0"); // create
    badOpcodes.push(hex"f5"); // create2

OK:
0A	EXP	A1                          a, b	a ** b		                        uint256 exponentiation modulo 2**256	
0B	SIGNEXTEND 5	                b, x	SIGNEXTEND(x, b)		            sign extend x from (b+1) bytes to 32 bytes
15	ISZERO	3	                    a	    a == 0		                        (u)int256 iszero
16	AND	3	                        a, b	a && b		                        bitwise AND	
17	OR	3	                        a, b	a \|\| b                            bitwise OR
1A	BYTE	3	                    i, x	(x >> (248 - i * 8)) && 0xFF		ith byte of (u)int256 x, from the left
F4	DELEGATECALL AA 	            gas, addr, argOst, argLen, retOst, retLen	success	mem[retOst:retOst+retLen-1] := returndata
XOR = AND - OR

PUSH32 standard gas     // gas: the amount of gas the code may use in order to execute;
PUSH20 ADDR             // to: the destination address whose code is to be executed;
                        // in_offset: the offset into memory of the input;
                        // in_size: the size of the input in bytes;
                        // out_offset: the offset into memory of the output;
                        // out_size: the size of the scratch pad for the output.




