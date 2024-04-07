// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC20/IERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/security/Pausable.sol";

/**
 * @title ReferralGame
 * @dev Implements a simple referral system where participants earn points by referring others.
 * Participants are incentivized to grow their referral network to earn more points.
 *
 * Functions include joining the game, updating reward levels, checking points,
 * pausing the game for maintenance, and emergency withdrawal of tokens.
 */
contract ReferralGame is Ownable, Pausable {
    IERC20 public beansToken; // ERC20 token to be used for rewards, set at contract deployment.
    mapping(address => address) public referrer; // Maps a user to their referrer.
    mapping(address => uint256) public points; // Tracks points earned by each user.
    mapping(uint256 => uint256) public rewardPerLevel; // Points rewarded per referral level, initialized in the constructor.

    uint256 public constant MAX_LEVEL = 15; // Maximum depth for referral rewards.

    event Joined(address indexed user, address indexed referrer);
    event PointsEarned(address indexed user, uint256 points);

    /**
     * @notice Constructor to set up the referral game.
     * @param beansTokenAddress Address of the ERC20 token to be used for rewards.
     */
    constructor(address beansTokenAddress) {
        beansToken = IERC20(beansTokenAddress);
        initializeRewards(); // Set initial reward points for referral levels.
    }

    /**
     * @notice Initializes the points rewarded for each referral level.
     * @dev Sets 100 points for direct referrals (level 1) and halves the points for each subsequent level.
     */
    function initializeRewards() internal {
        rewardPerLevel[1] = 100; // Direct referrals earn 100 points.
        for (uint256 i = 2; i <= MAX_LEVEL; i++) {
            rewardPerLevel[i] = rewardPerLevel[i - 1] / 2; // Halving points for each level down.
        }
    }

    /**
     * @notice Allows a new user to join the game by specifying a referrer.
     * @param referrerAddress The address of the referrer (existing participant).
     * @dev Points are distributed up the referral chain, up to MAX_LEVEL.
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
     * @notice Returns the points earned by a given user.
     * @param user Address of the user to check points for.
     * @return The number of points earned by the user.
     */
    function checkPoints(address user) external view returns (uint256) {
        return points[user];
    }

    /**
     * @notice Allows the owner to update the reward points for a specific referral level.
     * @param level The referral level to update points for (1 to MAX_LEVEL).
     * @param newReward The new number of points to be awarded for the specified level.
     * @dev Ensure the level is within the valid range before updating.
     */
    function updateRewardPerLevel(uint256 level, uint256 newReward) external onlyOwner {
        require(level > 0 && level <= MAX_LEVEL, "Invalid referral level.");
        rewardPerLevel[level] = newReward;
    }

    /**
     * @notice Pauses the game, disabling the ability for users to join. Only callable by the contract owner.
     * @dev Useful for maintenance or in response to critical issues.
     */
    function pauseGame() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the game, allowing users to join again. Only callable by the contract owner.
     */
    function unpauseGame() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Allows the owner to withdraw ERC20 tokens from the contract, in case of emergency or error.
     * @param tokenAddress The contract address of the ERC20 token to withdraw.
     * @param amount The amount of tokens to withdraw.
     * @dev Can be used to recover tokens sent to the contract by mistake.
     */
    function emergencyWithdrawTokens(address tokenAddress, uint256 amount) external onlyOwner {
        require(IERC20(tokenAddress).transfer(owner(), amount), "Token transfer failed.");
    }
}
