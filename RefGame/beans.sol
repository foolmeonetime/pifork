// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/access/Ownable.sol";

/**
 * @title Beans
 * @dev ERC20 Token that integrates a referral game, where participants earn points for referring others.
 */
contract Beans is ERC20, Ownable {
    mapping(address => address) public referrer; // Maps a user to their referrer
    mapping(address => uint256) public points; // Tracks points earned by each user
    mapping(uint256 => uint256) public rewardPerLevel; // Points rewarded per referral level

    uint256 public constant MAX_LEVEL = 15; // Maximum depth for referral rewards

    constructor() ERC20("Beans", "BEANS") {
        initializeRewards(); // Set initial reward points for referral levels
    }

    // Initialize the points rewarded for each referral level
    function initializeRewards() internal {
        rewardPerLevel[1] = 100; // Direct referrals earn 100 points
        for (uint256 i = 2; i <= MAX_LEVEL; i++) {
            rewardPerLevel[i] = rewardPerLevel[i - 1] / 2; // Halve the points for each subsequent level
        }
    }

    /**
     * @dev Allows a new user to join the game by specifying a referrer.
     * Points are distributed up the referral chain, up to MAX_LEVEL.
     * @param referrerAddress The address of the user's referrer.
     */
    function join(address referrerAddress) external {
        require(referrer[msg.sender] == address(0), "User has already joined.");
        require(referrerAddress != msg.sender, "Cannot refer oneself.");
        require(referrerAddress != address(0), "Referrer cannot be the zero address.");

        referrer[msg.sender] = referrerAddress;
        // Distribute points up the referral chain
        address currentReferrer = referrerAddress;
        for (uint256 level = 1; level <= MAX_LEVEL && currentReferrer != address(0); level++) {
            points[currentReferrer] += rewardPerLevel[level];
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
        points[msg.sender] = 0; // Reset points to zero after withdrawal
        _mint(msg.sender, userPoints); // Mint ERC20 tokens for the user
    }

    // Override required due to Solidity multiple inheritance rules
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    // Administrative function to update reward levels
    function updateRewardPerLevel(uint256 level, uint256 newReward) external onlyOwner {
        require(level > 0 && level <= MAX_LEVEL, "Invalid referral level.");
        rewardPerLevel[level] = newReward;
    }
}
