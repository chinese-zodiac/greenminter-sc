// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
// If you read this, know that I love you even if your mom doesnt <3
const chai = require('chai');
const { solidity } = require("ethereum-waffle");
chai.use(solidity);

const { ethers, config } = require('hardhat');
const { time } = require("@openzeppelin/test-helpers");
const { toNum, toBN } = require("./utils/bignumberConverter");
const parse = require('csv-parse');
const { expect } = chai;
const { parseEther, formatEther, defaultAbiCoder } = ethers.utils;

const BASE_CZUSD_LP_WAD = parseEther("10000");
const CZUSD_TOKEN = "0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70";
const BUSD_TOKEN = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56";
const PCS_FACTORY = "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73";
const PCS_ROUTER = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
const DEPLOYER = "0x70e1cB759996a1527eD1801B169621C18a9f38F9";


describe("Gem", function () {
  let owner, manager, trader, trader1, trader2, trader3;
  let deployer;
  let gem, czusd, pcsRouter, gemCzusdPair;
  before(async function() {
    [owner, manager, trader, trader1, trader2, trader3] = await ethers.getSigners();
    await hre.network.provider.request({ 
      method: "hardhat_impersonateAccount",
      params: [DEPLOYER]
    });
    deployer = await ethers.getSigner(DEPLOYER);

    pcsRouter = await ethers.getContractAt("IAmmRouter02", PCS_ROUTER);
    czusd = await ethers.getContractAt("CZUsd", CZUSD_TOKEN);

    const Gem = await ethers.getContractFactory("Gem");
    gem = await Gem.deploy(
      CZUSD_TOKEN,
      PCS_ROUTER,
      PCS_FACTORY,
      manager.address,
      BASE_CZUSD_LP_WAD
    );
    
    const gemCzusdPair_address = await gem.ammCzusdPair();
    gemCzusdPair = await ethers.getContractAt("IAmmPair", gemCzusdPair_address);
    
    await czusd
    .connect(deployer)
    .grantRole(ethers.utils.id("MINTER_ROLE"), gem.address);

    await czusd.connect(deployer).mint(owner.address,BASE_CZUSD_LP_WAD);
    await gem.approve(pcsRouter.address,ethers.constants.MaxUint256);
    await czusd.approve(pcsRouter.address,ethers.constants.MaxUint256);
    await pcsRouter.addLiquidity(
      czusd.address,
      gem.address,
      BASE_CZUSD_LP_WAD,
      parseEther("200000"),
      0,
      0,
      gem.address,
      ethers.constants.MaxUint256
    );
  });
  it("Should deploy gem", async function () {
    const pairCzusdBal = await czusd.balanceOf(gemCzusdPair.address);
    const pairGemBal = await gem.balanceOf(gemCzusdPair.address);
    const baseCzusdLocked = await gem.baseCzusdLocked();
    const totalCzusdSpent = await gem.totalCzusdSpent();
    const ownerIsExempt = await gem.isExempt(owner.address);
    const pairIsExempt = await gem.isExempt(gemCzusdPair.address);
    const tradingOpen = await gem.tradingOpen();
    //const availableWadToSend = await gem.availableWadToSend();
    expect(pairCzusdBal).to.eq(BASE_CZUSD_LP_WAD);
    expect(pairGemBal).to.eq(parseEther("200000"));
    expect(baseCzusdLocked).to.eq(BASE_CZUSD_LP_WAD);
    expect(totalCzusdSpent).to.eq(0);
    expect(ownerIsExempt).to.be.true;
    expect(pairIsExempt).to.be.false;
    expect(tradingOpen).to.be.false;
    //expect(availableWadToSend).to.eq(0);
  });
});