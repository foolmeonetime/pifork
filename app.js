let selectedAccount;
let isConnected = false;

window.addEventListener('load', () => {
    document.getElementById('connectWalletButton').addEventListener('click', connectWallet);
});

async function connectWallet() {
    if (window.ethereum) {
        try {
            const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
            selectedAccount = accounts[0];
            isConnected = true;
            await checkNetwork();
            updateUI();
        } catch (error) {
            alert(`Failed to connect wallet: ${error.message}`);
            isConnected = false;
        }
    } else {
        alert('Please install MetaMask or another Ethereum wallet to use this app.');
        isConnected = false;
    }
}

async function checkNetwork() {
    const chainId = await web3.eth.getChainId();
    if (chainId !== 6969696969) {
        alert('Please connect to Magma Testnet');
        isConnected = false;
    }
}

async function joinGame() {
    if (!isConnected || !selectedAccount) {
        alert('Please connect your wallet.');
        return;
    }
    const referrerAddress = document.getElementById('referrerAddress').value;
    contract.methods.join(referrerAddress).send({ from: selectedAccount })
        .then(function(receipt) {
            alert("Successfully joined the game!");
        })
        .catch(function(error) {
            alert("Error joining game: " + error.message);
        });
}

async function withdrawPoints() {
    if (!isConnected || !selectedAccount) {
        alert('Please connect your wallet.');
        return;
    }
    contract.methods.withdrawPoints().send({ from: selectedAccount })
        .then(function(receipt) {
            alert("Successfully withdrawn points!");
        })
        .catch(function(error) {
            alert("Error withdrawing points: " + error.message);
        });
}

async function checkBalance() {
    if (!isConnected || !selectedAccount) {
        alert('Please connect your wallet.');
        return;
    }
    contract.methods.balanceOf(selectedAccount).call()
        .then(function(balance) {
            document.getElementById('balance').innerText = `Your Balance: ${balance} BEANS`;
        })
        .catch(function(error) {
            alert("Error checking balance: " + error.message);
        });
}

function updateUI() {
    document.getElementById('walletInfo').innerText = `Connected: ${selectedAccount.substring(0, 6)}...${selectedAccount.substring(selectedAccount.length - 4)} on Magma Testnet`;
}

// Initialize Web3
const web3 = new Web3(window.ethereum);

// Initialize contract with ABI and address imported from contractABI.js
const contract = new web3.eth.Contract(contractABI, contractAddress);
