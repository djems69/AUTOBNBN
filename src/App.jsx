import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import StakingABI from '../contracts/Staking.json';
import './App.css';

const App = () => {
  const [account, setAccount] = useState('');
  const [balance, setBalance] = useState('0');
  const [stakedAmount, setStakedAmount] = useState('0');
  const [rewards, setRewards] = useState('0');
  const [isConnected, setIsConnected] = useState(false);
  const [contract, setContract] = useState(null);
  const [provider, setProvider] = useState(null);

  const CONTRACT_ADDRESS = "YOUR_DEPLOYED_CONTRACT_ADDRESS";

  useEffect(() => {
    if (window.ethereum) {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      setProvider(provider);
      
      const contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        StakingABI.abi,
        provider.getSigner()
      );
      setContract(contract);
    }
  }, []);

  const connectWallet = async () => {
    try {
      if (window.ethereum) {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        setAccount(accounts[0]);
        setIsConnected(true);
        updateBalances();
      } else {
        alert('Please install MetaMask!');
      }
    } catch (error) {
      console.error('Error connecting wallet:', error);
    }
  };

  const updateBalances = async () => {
    if (contract && account) {
      const balance = await provider.getBalance(account);
      setBalance(ethers.utils.formatEther(balance));
      
      const stake = await contract.stakes(account);
      setStakedAmount(ethers.utils.formatEther(stake.amount));
      
      const rewards = await contract.calculateRewards(account);
      setRewards(ethers.utils.formatEther(rewards));
    }
  };

  const stake = async (amount) => {
    try {
      const tx = await contract.stake({
        value: ethers.utils.parseEther(amount)
      });
      await tx.wait();
      updateBalances();
    } catch (error) {
      console.error('Error staking:', error);
    }
  };

  const unstake = async () => {
    try {
      const tx = await contract.unstake();
      await tx.wait();
      updateBalances();
    } catch (error) {
      console.error('Error unstaking:', error);
    }
  };

  const claimRewards = async () => {
    try {
      const tx = await contract.claimRewards();
      await tx.wait();
      updateBalances();
    } catch (error) {
      console.error('Error claiming rewards:', error);
    }
  };

  return (
    <div className="app">
      <header>
        <h1>Golden Egg Staking</h1>
        {!isConnected ? (
          <button onClick={connectWallet}>Connect Wallet</button>
        ) : (
          <div className="wallet-info">
            <span>{account.substring(0, 6)}...{account.substring(account.length - 4)}</span>
            <span>Balance: {balance} BNB</span>
          </div>
        )}
      </header>

      <main>
        <section className="staking-section">
          <h2>Stake BNB, Earn Rewards</h2>
          <div className="staking-info">
            <div className="info-card">
              <h3>Your Stake</h3>
              <p>{stakedAmount} BNB</p>
            </div>
            <div className="info-card">
              <h3>Available Rewards</h3>
              <p>{rewards} BNB</p>
            </div>
          </div>

          <div className="staking-actions">
            <button onClick={() => stake('0.1')}>Stake 0.1 BNB</button>
            <button onClick={() => stake('1')}>Stake 1 BNB</button>
            <button onClick={() => stake('5')}>Stake 5 BNB</button>
          </div>

          <div className="action-buttons">
            <button onClick={unstake}>Unstake</button>
            <button onClick={claimRewards}>Claim Rewards</button>
          </div>
        </section>

        <section className="stats-section">
          <h2>Staking Statistics</h2>
          <div className="stats-grid">
            <div className="stat-card">
              <h3>Total Value Locked</h3>
              <p>Loading...</p>
            </div>
            <div className="stat-card">
              <h3>APR</h3>
              <p>15%</p>
            </div>
            <div className="stat-card">
              <h3>Total Stakers</h3>
              <p>Loading...</p>
            </div>
          </div>
        </section>
      </main>

      <footer>
        <p>© 2024 Golden Egg Staking. All rights reserved.</p>
      </footer>
    </div>
  );
};

export default App; 