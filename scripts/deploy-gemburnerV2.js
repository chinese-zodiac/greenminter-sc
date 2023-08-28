const hre = require("hardhat");
const loadJsonFile = require("load-json-file");

const { ethers } = hre;
const { parseEther } = ethers.utils;

async function main() {

  const GemBurnerV2 = await ethers.getContractFactory("GemBurnerV2");
  const gemBurner = await GemBurnerV2.deploy();
  await gemBurner.deployed();
  console.log("GemBurnerV2 deployed to:", gemBurner.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
