import { ethers } from "hardhat";

async function main(): Promise<void> {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploying the mock ERC20 token 
  const Token = await ethers.getContractFactory("MockERC20");
  const token = await Token.deploy("Mock Token", "MTK");
  await token.deployed();
  console.log("Mock Token deployed to:", token.address);

  // Deploying the Auction contract
  const Auction = await ethers.getContractFactory("Auction");
  const auction = await Auction.deploy();
  await auction.deployed();
  console.log("Auction deployed to:", auction.address);
  await auction.initialize();
  console.log("Auction initialized");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
