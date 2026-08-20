// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TrueCashPaymaster is Ownable {
    ERC20Permit public truecash;
    
    // Anti-spam requirement: Must hold 2,000 TCASH to transact for free
    uint256 public constant MINIMUM_BALANCE_REQUIRED = 2000 * 10**18;
    
    // Rate limit: 5 free transactions per 24 hours
    uint256 public constant MAX_DAILY_TX = 5;
    uint256 public constant RESET_PERIOD = 24 hours;

    // Dynamic Miner Reward (default 5 TCASH)
    uint256 public currentMinerReward = 5 * 10**18;

    struct RateLimit {
        uint256 txCount;
        uint256 lastResetTime;
    }

    mapping(address => RateLimit) public userLimits;

    event ZeroGasTransactionExecuted(address indexed from, address indexed to, uint256 amount);
    event ZeroGasOrderPaid(address indexed merchant, address indexed customer, uint256 amount, string orderId);
    event MinerRewardPaid(address indexed miner, uint256 amount);
    event MinerRewardUpdated(uint256 newRewardAmount);

    constructor(address _truecash) Ownable(msg.sender) {
        truecash = ERC20Permit(_truecash);
    }

    /**
     * @dev Allows the Treasury to dynamically adjust the TCASH reward for miners.
     */
    function setMinerReward(uint256 _newReward) external onlyOwner {
        currentMinerReward = _newReward;
        emit MinerRewardUpdated(_newReward);
    }

    /**
     * @dev Executes a zero-gas transaction on behalf of a user using ERC20Permit.
     * The relayer (this contract or its owner) pays the network gas fee.
     * @param from The user sending the tokens (must hold MINIMUM_BALANCE_REQUIRED).
     * @param to The recipient of the tokens.
     * @param amount The amount of tokens to send.
     * @param orderId The unique order identifier from the merchant's backend.
     * @param deadline The EIP-712 permit deadline.
     * @param v secp256k1 signature parameter v.
     * @param r secp256k1 signature parameter r.
     * @param s secp256k1 signature parameter s.
     */
    function executeZeroGasTx(
        address from,
        address to,
        uint256 amount,
        string memory orderId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // 1. Enforce Anti-Spam Balance Requirement
        require(
            IERC20(address(truecash)).balanceOf(from) >= MINIMUM_BALANCE_REQUIRED,
            "Paymaster: Insufficient TrueCash balance for zero-gas feature"
        );

        // 2. Enforce Daily Rate Limiting
        RateLimit storage limitData = userLimits[from];
        if (block.timestamp >= limitData.lastResetTime + RESET_PERIOD) {
            // Reset the counter if 24 hours have passed
            limitData.txCount = 0;
            limitData.lastResetTime = block.timestamp;
        }
        require(limitData.txCount < MAX_DAILY_TX, "Paymaster: Daily zero-gas transaction limit reached");
        
        // Increment their transaction count
        limitData.txCount += 1;

        // 3. Execute Permit (Allows this contract to transfer `amount` from the user)
        truecash.permit(from, address(this), amount, deadline, v, r, s);

        // 4. Execute the Transfer (Customer to Merchant)
        require(IERC20(address(truecash)).transferFrom(from, to, amount), "Paymaster: Token transfer failed");

        emit ZeroGasTransactionExecuted(from, to, amount);
        
        // Emit the merchant reconciliation event if an orderId is provided
        if (bytes(orderId).length > 0) {
            emit ZeroGasOrderPaid(to, from, amount, orderId);
        }

        // 5. Pay the Miner Reward from the Paymaster's Treasury Balance
        if (currentMinerReward > 0) {
            require(
                IERC20(address(truecash)).balanceOf(address(this)) >= currentMinerReward,
                "Paymaster: Insufficient Treasury balance to pay miner reward"
            );
            require(IERC20(address(truecash)).transfer(msg.sender, currentMinerReward), "Paymaster: Miner reward transfer failed");
            emit MinerRewardPaid(msg.sender, currentMinerReward);
        }
    }

    /**
     * @dev Allows the protocol to fund the paymaster with native ETH/BNB to pay gas.
     */
    receive() external payable {}

    /**
     * @dev Withdraw native ETH/BNB from the paymaster (Treasury management).
     */
    function withdrawNative() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    /**
     * @dev Withdraw excess TCASH from the paymaster (Treasury management).
     */
    function withdrawTrueCash(uint256 amount) external onlyOwner {
        require(IERC20(address(truecash)).transfer(owner(), amount), "Paymaster: Withdraw failed");
    }
}
