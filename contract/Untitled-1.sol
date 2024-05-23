// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GameToken is ERC20 {
    address public immutable deployer;
    uint256 public totalMines;
    uint256 public totalPlayers;
    uint256 private _inviteCounter;
    mapping(address => address) private _referrers;
    mapping(address => uint256) private _beansAccumulated;
    mapping(address => uint256) private _playerLevel;
    mapping(address => bool) private _inGame;
    mapping(uint256 => address) private _inviteIdToAddress;
    bool private _paused;
    address public gasToken; // Address of the gas token contract
    uint256 public gasTokenPrice; // Price of gas token in wei

    event PlayerJoinedGame(address indexed player, address indexed referral);
    event Mine(address indexed miner);
    event InviteSent(address indexed sender, address indexed recipient, uint256 indexed inviteId);
    event TeamCreated(address indexed teamOwner, string teamName);
    event RewardsClaimed(address indexed player, uint256 indexed amount);
    event Paused();
    event Unpaused();

    constructor(address _gasToken, uint256 _gasTokenPrice) ERC20("Lava Beans", "BEAN") {
        deployer = msg.sender;
        gasToken = _gasToken;
        gasTokenPrice = _gasTokenPrice;
        _mint(msg.sender, 420000069 * 10 ** decimals());
        _inGame[msg.sender] = true;
        totalPlayers = 1; // Deployer is the first player
    }

    function joinGame(address referral) external {
        require(!_inGame[msg.sender], "You are already in the game.");
        require(balanceOf(msg.sender) == 0, "You are already a player.");
        require(balanceOf(referral) > 0 || referral == deployer, "Referral does not exist in the game.");
        
        _referrers[msg.sender] = referral;
        _inGame[msg.sender] = true;
        totalPlayers++;
        _playerLevel[msg.sender] = totalPlayers % 5 == 0 ? _playerLevel[msg.sender] + 1 : _playerLevel[msg.sender];
        _mint(msg.sender, 100 * 10 ** decimals());
        
        emit PlayerJoinedGame(msg.sender, referral);
    }

    function mine() external whenNotPaused {
        require(_inGame[msg.sender], "You are not in the game.");
        
        _beansAccumulated[msg.sender]++;
        totalMines++;
        
        emit Mine(msg.sender);
    }

    function invite(address playerToInvite) external whenNotPaused {
        require(_inGame[msg.sender], "You are not in the game.");
        require(_inGame[playerToInvite], "The player you are trying to invite is not in the game.");
        
        _inviteCounter++;
        _inviteIdToAddress[_inviteCounter] = playerToInvite;
        
        emit InviteSent(msg.sender, playerToInvite, _inviteCounter);
    }

    function createTeam(string memory teamName) external {
        require(_inGame[msg.sender], "You are not in the game.");
        require(bytes(teamName).length > 0, "Please provide a name for your team.");
        
        // Additional logic for creating a team...
        
        emit TeamCreated(msg.sender, teamName);
    }

    function acceptInvite(uint256 inviteId) external view whenNotPaused returns (bool) {
        require(_inGame[msg.sender], "You are not in the game.");
        return _inviteIdToAddress[inviteId] == msg.sender;
    }

    function claimRewards() external whenNotPaused {
        require(_inGame[msg.sender], "You are not in the game.");
        
        uint256 rewards = _beansAccumulated[msg.sender];
        _beansAccumulated[msg.sender] = 0;
        
        // Transfer reward tokens from deployer's wallet to player's wallet
        _transfer(deployer, msg.sender, rewards);
        
        // Calculate the amount of gas tokens to transfer
        uint256 gasTokensRequired = gasTokenPrice;
        
        // Transfer gas tokens from player to deployer
        require(ERC20(gasToken).transferFrom(msg.sender, deployer, gasTokensRequired), "Gas token transfer failed");
        
        emit RewardsClaimed(msg.sender, rewards);
    }

    function pause() external onlyOwner whenNotPaused {
        _paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused();
    }

    function getPlayerReferrer(address player) external view returns (address) {
        return _referrers[player];
    }

    function getPlayerBeansAccumulated(address player) external view returns (uint256) {
        return _beansAccumulated[player];
    }

    function getPlayerLevel(address player) external view returns (uint256) {
        return _playerLevel[player];
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Contract is not paused");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == deployer, "Only deployer can call this function.");
        _;
    }
}
