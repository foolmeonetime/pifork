// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/token/ERC20/ERC20.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.4.0/contracts/access/Ownable.sol";

contract Beans is ERC20, Ownable {
    mapping(address => address) public referrer; // Maps a user to their referrer
    mapping(address => uint256) public totalEarnings; // Total BEANS earned by each user
    mapping(address => uint256) public withdrawnBEANS; // Total BEANS withdrawn by each user
    uint256 public totalUsers = 0; // Total number of users who joined
    address[] public topReferrers; // Dynamic array to track top referrers (updated manually or through a function)

    uint256 public constant BASE_REWARD = 1000 * 10**18; // Base reward for direct referrals
    uint256 public constant MAX_LEVEL = 15; // Maximum referral depth
    uint256 public constant JOINING_BEANS = 10000 * 10**18; // BEANS given upon joining

    constructor() ERC20("Beans", "BEANS") {}

    function join(address referrerAddress) external {
        require(referrer[msg.sender] == address(0), "User has already joined.");
        require(referrerAddress != msg.sender, "Cannot refer oneself.");
        require(referrerAddress != address(0), "Referrer cannot be the zero address.");

        totalUsers += 1; // Increment total users
        _mint(msg.sender, JOINING_BEANS); // Mint joining BEANS
        totalEarnings[msg.sender] += JOINING_BEANS; // Update total earnings

        referrer[msg.sender] = referrerAddress; // Set referrer
        uint256 reward = BASE_REWARD;

        // Distribute rewards up the referral chain
        for (uint256 level = 1; level <= MAX_LEVEL && referrerAddress != address(0); level++) {
            _mint(referrerAddress, reward); // Mint reward for the referrer
            totalEarnings[referrerAddress] += reward; // Update referrer's total earnings

            referrerAddress = referrer[referrerAddress]; // Move up in the referral chain
            reward /= 2; // Halve the reward for the next level
        }

        // Optionally update top referrers list here or through a separate function
    }

    function withdrawBEANS() external {
        uint256 availableBEANS = totalEarnings[msg.sender] - withdrawnBEANS[msg.sender];
        require(availableBEANS > 0, "No BEANS available for withdrawal.");

        withdrawnBEANS[msg.sender] += availableBEANS; // Update withdrawn BEANS
        _mint(msg.sender, availableBEANS); // Mint available BEANS to user
    }

    function getTotalUsers() external view returns (uint256) {
        return totalUsers;
    }

    function getAvailableBEANSToWithdraw(address user) external view returns (uint256) {
        return totalEarnings[user] - withdrawnBEANS[user];
    }

    function getTopReferrers() external view returns (address[] memory) {
        return topReferrers;
    }
}

