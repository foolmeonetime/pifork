// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/security/Pausable.sol";

/**
 * @title TheReferralGame
 * @dev A referral game where participants earn points for referring others, withdrawable as BEANS tokens.
 * This contract integrates basic ERC20 token functionality, minting tokens upon points withdrawal.
 */
contract TheReferralGame is Ownable, Pausable {
    mapping(address => address) public referrer; // Maps a user to their referrer.
    mapping(address => uint256) public points; // Tracks points earned by each user.
    mapping(uint256 => uint256) public rewardPerLevel; // Points rewarded per referral level.

    string public constant name = "Beans";
    string public constant symbol = "BEANS";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 999999999999 * (10**uint256(decimals)); // Max supply including decimals.
    uint256 public constant MAX_LEVEL = 15; // Maximum depth for referral rewards.

    mapping(address => uint256) private balances;

    event Joined(address indexed user, address indexed referrer);
    event PointsEarned(address indexed user, uint256 points);
    event TokensMinted(address indexed user, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() {
        initializeRewards(); // Set initial reward points for referral levels.
    }

    // Initialize the points rewarded for each referral level.
    function initializeRewards() internal {
        rewardPerLevel[1] = 100; // Direct referrals earn 100 points.
        for (uint256 i = 2; i <= MAX_LEVEL; i++) {
            rewardPerLevel[i] = rewardPerLevel[i - 1] / 2; // Halve the points for each level down.
        }
    }

    /**
     * @dev Allows a new user to join the game by specifying a referrer.
     * Points are distributed up the referral chain, up to MAX_LEVEL.
     * @param referrerAddress The address of the user's referrer.
     */
    function join(address referrerAddress) external whenNotPaused {
        require(referrer[msg.sender] == address(0), "User has already joined.");
        require(referrerAddress != msg.sender, "Cannot refer oneself.");

        referrer[msg.sender] = referrerAddress;
        emit Joined(msg.sender, referrerAddress);

        // Distribute points up the referral chain.
        address currentReferrer = referrerAddress;
        for (uint256 level = 1; level <= MAX_LEVEL && currentReferrer != address(0); level++) {
            points[currentReferrer] += rewardPerLevel[level];
            emit PointsEarned(currentReferrer, rewardPerLevel[level]);
            currentReferrer = referrer[currentReferrer];
        }
    }

    /**
     * @dev Allows users to withdraw their earned points as BEANS tokens.
     * Each point is equivalent to one BEANS token.
     */
    function withdrawPoints() external {
        uint256 userPoints = points[msg.sender];
        require(userPoints > 0, "No points to withdraw.");

        uint256 mintAmount = userPoints * (10**uint256(decimals)); // Convert points to token amount.
        require(totalSupply + mintAmount <= MAX_SUPPLY, "Minting would exceed max supply.");

        points[msg.sender] = 0; // Reset points to zero after withdrawal.
        totalSupply += mintAmount;
        balances[msg.sender] += mintAmount;

        emit TokensMinted(msg.sender, mintAmount);
        emit Transfer(address(0), msg.sender, mintAmount); // Emit a transfer event from the zero address for minting.
    }

    /**
     * @dev Returns the balance of BEANS tokens held by a given account.
     * @param account The address of the account to check.
     * @return The balance of BEANS tokens held by the account.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Transfers BEANS tokens from the caller's account to another account.
     * @param recipient The address of the recipient.
     * @param amount The amount of tokens to transfer.
     * @return True if the transfer was successful, otherwise false.
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(balances[msg.sender] >= amount, "Not enough balance.");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    // Administrative functions to pause/unpause the game and update reward levels.
    function pauseGame() external onlyOwner {
        _pause();
    }

    function unpauseGame() external onlyOwner {
        _unpause();
    }

    function updateRewardPerLevel(uint256 level, uint256 newReward) external onlyOwner {
        require(level > 0 && level <= MAX_LEVEL, "Invalid referral level.");
        rewardPerLevel[level] = newReward;
    }
}
