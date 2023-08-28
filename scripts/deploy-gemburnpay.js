const hre = require("hardhat");
const loadJsonFile = require("load-json-file");

const { ethers } = hre;
const { parseEther } = ethers.utils;

async function main() {

  const GemBurnPay = await ethers.getContractFactory("GemBurnPay");
  const gemBurnPay = await GemBurnPay.deploy();
  await gemBurnPay.deployed();
  console.log("GemBurnPay deployed to:", gemBurnPay.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
