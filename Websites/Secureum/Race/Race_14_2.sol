interface Lender {
    function onLiquidation() external;
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ERC20Collateral {
    // This contract is different from the one in Questions 1 & 2, please read it carefully!!!
    // This is a contract that's part of a larger system implementing a lending protocol

    // A list of all the addresses lending
    address[] lenders;
    // A mapping to allow efficient is lender checks
    mapping(address => bool) isLender;

    address immutable lendingPlatform = msg.sender;
    IERC20 token;

    // We use a mapping to store the deposits of all lenders
    mapping (address => uint256) balance;

    event Liquidation(address indexed lender, uint256 liquidatedAmount);

    constructor(IERC20 _token) {
        // Consider this contract is now part of a new permissionless factory
        // built by the protocol. The factory behaves very much like a UniswapV2 factory
        // that allows anyone to deploy their own collateral contract
        token = _token;
    }

    function deposit(uint amount) external {
        isLender[msg.sender] = true;
        lenders.push(msg.sender);

        token.transferFrom(msg.sender, lendingPlatform, amount);
        balance[msg.sender] += amount;
    }

    function liquidate(address lender) external {
        // We call the protocol factory to check for under-collateralization conditions
        require(lendingPlatform.undercollateralized(lender, balance[lender]));

        uint256 oldDeposit = balance[lender];
        balance[lender] = 0;
        uint256 fee = oldDeposit / 1000; // fee ratio == 1/1000

        // Give the caller his liquidation execution fee
        token.transferFrom(address(this), msg.sender, fee);
        // Transfer the rest of the collateral to the platform
        token.transferFrom(address(this), lendingPlatform, oldDeposit - fee);

        // Now ping the liquidated lender for him to be able to react to the liquidation
        // We need to use a low-level call because the lender might not be a contract
        // and the compiler checks code size on high-level calls, reverting if it's 0
        address(lender).call(abi.encodePacked(Lender.onLiquidation.selector));

        emit Liquidation(lender, oldDeposit - balance[lender]);
    }