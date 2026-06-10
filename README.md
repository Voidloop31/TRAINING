# Dead Man's Switch

A blockchain-based dead man's switch smart contract built with Solidity and Foundry.

## What it does
Owner must check in every hour. If they miss a check-in,
anyone can trigger the grace period. After 30 minutes,
beneficiaries can claim the funds automatically — no lawyers, no banks.

## Contract Addresses (Sepolia Testnet)
- **DeadMansSwitch:** 0x7FD7Ccb46321481F0Edf04fDdb5a3bE8A3FA7051
- **SwitchFactory:** 0xD66C65F6f40F0dd7620A52d39d2542E814947C9A

## Project Structure
- `src/DeadMansSwitch.sol` — core contract + factory
- `test/DeadMansSwitch.t.sol` — Foundry unit tests
- `frontend/index.html` — web frontend using ethers.js

## How to run tests
forge test -vv

## Test Coverage
- Lines: 87.23%
- Statements: 84.44%
- Functions: 88.89%

## Frontend
Open frontend/index.html in a browser with MetaMask installed.

## Resources
- Foundry: https://getfoundry.sh
- Sepolia Etherscan: https://sepolia.etherscan.io
