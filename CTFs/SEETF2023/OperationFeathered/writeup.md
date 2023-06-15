


## Analysis

- contract for managing pigeons of differet tiers (junio, associate, senior)
- pigeons have to fulfill tasks to increase their points

### Functions

#### constructor()

sets owner and values for the promotions

### becomeAPigeon(string memory code, string memory name)
reverts if:
- codeToName[code][name] is true, which is either set to true in this function or in assignPigeon().
- isPigeon[msg.sender] is true

functionality:
- hashes code and name together to generate codeName (reproducible)
- sets juniorPigeon at the generated codename to the address of the msg sender
- sets isPigeon[msg.sender] to true
- sets codeToName[code][name] to true (which will trigger the revert if we call this fun again with the same val)

### task(bytes32 codeName, address person, uint256 data)
reverts if:
- !isPigeon[myśg.sender]
- person == address(0)
- isPigeon[person]
- person.balance != data

functionality
- increases taskpoints of the given codeName by points

### flyAway(bytes32 codeName, uint256 rank)
reverts if:
- !isPigeon[msg.sender]
- rank == 0 && taskPoints[codeName] > juniorPromotion
- rank == 1 && taskPoints[codeName] > associatePromotion

functionality:
- sends the treasury[codeName] to the tiers mapping[codeName]


### promotion(bytes32 codeName, uint256 desiredRank, string memory newCode, string memory newName)
reverts if:
- !isPigeon[myg.sender]
- msg.sender is not in the list corresponding to its rank
- taskPoints are less than the ones needed for the rank
- codeToName[newCode][newName] exists

functionality:
- increases the owner balance by the value of the trasury at the codename
- sets the ranks mapping[newCodeName] at to msg.sender
- resets the taskpoints of the old codename to 0
- deletes the old codename from its old ranks mapping
- transfers the treasury of the old codename to the owner

### assignPigeon(string memory code, string memory name, address pigeon, uint256 rank)
reverts if:
- owner != msg.sender

functionality:
- add a pigeon of arbitrary rank

## Solution

### What do we need to achieve?
address(msg.sender).balance >= 34 ether && address(pigeon).balance == 0 ether;

We only need to get the money of the 0 tier pigeon, as we already have 30 eth. Then we just need the contract to lose all other money.

### Step 1. Get money of the juniorpigeon