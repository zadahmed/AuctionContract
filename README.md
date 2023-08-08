# Auction Smart Contract 🎖

The Auction smart contract allows users to initiate and participate in decentralized auctions on the blockchain. 

## Table of Contents

- [Features](#features)
- [Installation](#installation)

## Features

- **Create Auctions:** Owners can initiate auctions with a specific token, start price, and duration.
- **Place Bids:** Users can place bids on active auctions, specifying their bid amount and price.
- **End Auction:** Auctions can be finalized by the owner immediately after their duration.

## Installation

Run yarn to install the package dependencies.
```bash
yarn
```

Compile the contracts 
```bash
npx hardhat compile
```

Run the contract tests
```bash
npx hardhat test
```

Deploy the contracts to hardhat
```bash
npx hardhat run scripts/deploy.js --network hardhat
```
