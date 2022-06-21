const hre = require("hardhat");
const loadJsonFile = require("load-json-file");

const {ethers} = hre;
const { parseEther } = ethers.utils;
const ITERABLE_ARRAY = "0x4222FFCf286610476B7b5101d55E72436e4a6065";
const CZUSD_TOKEN = "0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70";
const PCS_FACTORY = "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73";
const PCS_ROUTER = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
const GEM_DEV = "0x5B116abAc1817CebAd628B35BdE47e7296146AcF";

async function main() {

  const Gem = await ethers.getContractFactory("Gem");
  const gem = await Gem.deploy(
        CZUSD_TOKEN,//CZUsd _czusd,
        PCS_ROUTER,//IAmmRouter02 _ammRouter,
        PCS_FACTORY,//IAmmFactory _factory,
        GEM_DEV,//address _devWallet,
        parseEther("17306"),//uint256 _baseCzusdLocked,
        parseEther("256000")//uint256 _totalSupply
        );
  await gem.deployed();
  console.log("gem deployed to:", gem.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
