const hre = require("hardhat");
const loadJsonFile = require("load-json-file");

const {ethers} = hre;
const { parseEther } = ethers.utils;
const ITERABLE_ARRAY = "0x4222FFCf286610476B7b5101d55E72436e4a6065";

async function main() {

  const GemSale = await ethers.getContractFactory("GemSale",{
          libraries: {
            IterableArrayWithoutDuplicateKeys: ITERABLE_ARRAY,
          },
        });;
  const gemSale = await GemSale.deploy();
  await gemSale.deployed();
  console.log("GemSale deployed to:", gemSale.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
