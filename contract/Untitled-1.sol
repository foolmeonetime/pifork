// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BeanGame {
    address public owner; // Deployer wallet address
    uint256 public maxSupply = 42690000000 * 10**18; // Maximum supply of beans
    uint256 public beansMinted; // Total beans minted
    uint256 public referralReward = 420 * 10**18; // Beans rewarded for referrals
    uint256 public miningReward = 2.3 * 10**18; // Beans rewarded for mining
    bool public withdrawPaused = true; // Withdrawal functionality paused by default

    address public miningAddress; // Address to send mined beans

    mapping(address => uint256) public points; // Points earned by players
    mapping(address => uint256) public beansBalance; // Beans balance of players
    mapping(address => address) public referrer; // Referrer of each player
    mapping(address => uint256) public lastMiningTime; // Last mining time for each player
    mapping(address => uint256) public referralCount; // Referral count for each player
    mapping(address => uint256) public level; // Level of each player
    mapping(address => address) public playerTeam; // Team of each player
    mapping(address => address[]) public teamMembers; // Team members for each player
    mapping(address => mapping(address => bool)) public teamInvitations; // Team invitations

    uint256 public constant miningCooldown = 1 days; // Mining cooldown period
    uint256 public constant maxTeamSize = 50; // Maximum number of players per team

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier withdrawEnabled() {
        require(!withdrawPaused || msg.sender == owner, "Withdrawal is paused");
        _;
    }

    constructor(address _miningAddress) {
        owner = msg.sender;
        miningAddress = _miningAddress;
    }

    function joinGame(address _referrer) external {
        require(beansMinted + referralReward <= maxSupply, "Maximum supply reached");
        require(referrer[msg.sender] == address(0), "Player already joined");
        require(_referrer != msg.sender, "Cannot refer yourself");

        referrer[msg.sender] = _referrer;
        referralCount[_referrer]++;

        // Mint beans and send to the new player
        beansBalance[msg.sender] += referralReward;
        beansMinted += referralReward;

        // Update points and level based on referrals
        points[msg.sender] += 3;
        points[_referrer] += 3;
        updateLevel(msg.sender);
    }

    function inviteToTeam(address _player) external {
        require(teamMembers[msg.sender].length < maxTeamSize, "Team is full");
        require(playerTeam[_player] == address(0), "Player is already in a team");
        require(_player != msg.sender, "Cannot invite yourself to team");
        require(!teamInvitations[_player][msg.sender], "Invitation already sent");

        teamInvitations[_player][msg.sender] = true;
    }

    function acceptTeamInvite(address _teamOwner) external {
        require(teamInvitations[msg.sender][_teamOwner], "No pending invitation");
        require(teamMembers[_teamOwner].length < maxTeamSize, "Team is full");

        // Accept invitation
        teamInvitations[msg.sender][_teamOwner] = false;
        teamMembers[_teamOwner].push(msg.sender);
        playerTeam[msg.sender] = _teamOwner;
        referrer[msg.sender] = _teamOwner;
    }

    function checkReferralCount(address _player) external view returns (uint256) {
        return referralCount[_player];
    }

    function mineTokens() external {
        require(referrer[msg.sender] != address(0), "Player not joined");
        require(block.timestamp >= lastMiningTime[msg.sender] + miningCooldown, "Mining cooldown active");

        // Mint beans and send to the player
        beansBalance[msg.sender] += miningReward;
        beansMinted += miningReward;

        // Update points and level based on mining
        points[msg.sender] += 1;

        // Update points for referrer if exists
        address playerReferrer = referrer[msg.sender];
        if (playerReferrer != address(0)) {
            points[playerReferrer] += 1;
        }

        // Update level
        updateLevel(msg.sender);

        // Update last mining time
        lastMiningTime[msg.sender] = block.timestamp;

        // Send mined tokens to the designated mining address
        payable(miningAddress).transfer(miningReward);
    }

    function withdrawBeans(uint256 _amount) external withdrawEnabled {
        require(_amount <= beansBalance[msg.sender], "Insufficient balance");

        // Transfer beans to player
        beansBalance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function pauseWithdrawal() external onlyOwner {
        withdrawPaused = true;
    }

    function resumeWithdrawal() external onlyOwner {
        withdrawPaused = false;
    }

    function updateLevel(address player) private {
        uint256 currentLevel = level[player];
        uint256 referrals = referralCount[player];

        if (referrals >= 5 && referrals < 10 && currentLevel < 2) {
            level[player] = 2;
        } else if (referrals >= 10 && referrals < 15 && currentLevel < 3) {
            level[player] = 3;
        } else if (referrals >= 15 && referrals < 20 && currentLevel < 4) {
            level[player] = 4;
        } else if (referrals >= 20 && referrals < 25 && currentLevel < 5) {
            level[player] = 5;
        } else if (referrals >= 25 && referrals < 30 && currentLevel < 6) {
            level[player] = 6;
        } else if (referrals >= 30 && referrals < 35 && currentLevel < 7) {
            level[player] = 7;
        } else if (referrals >= 35 && referrals < 40 && currentLevel < 8) {
            level[player] = 8;
        } else if (referrals >= 40 && referrals < 45 && currentLevel < 9) {
            level[player] = 9;
        } else if (referrals >= 45 && referrals < 50 && currentLevel < 10) {
            level[player] = 10;
        } else if (referrals >= 50 && referrals < 55 && currentLevel < 11) {
            level[player] = 11;
        } else if (referrals >= 55 && referrals < 60 && currentLevel < 12) {
            level[player] = 12;
        } else if (referrals >= 60 && referrals < 65 && currentLevel < 13) {
            level[player] = 13;
        } else if (referrals >= 65 && referrals < 70 && currentLevel < 14) {
            level[player] = 14;
        } else if (referrals >= 70 && referrals < 75 && currentLevel < 15) {
            level[player] = 15;
        }
        // Add more conditions for higher levels if needed
    }
}
