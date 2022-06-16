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



describe("GemSale", function () {
  let owner, trader, trader1, trader2, trader3;
  let gemSale;
  before(async function() {
    [owner, trader, trader1, trader2, trader3] = await ethers.getSigners();

    const IterableArrayWithoutDuplicateKeys = await ethers.getContractFactory('IterableArrayWithoutDuplicateKeys')
    const iterableArrayWithoutDuplicateKeys = await IterableArrayWithoutDuplicateKeys.deploy()
    await iterableArrayWithoutDuplicateKeys.deployed();

    const GemSale = await ethers.getContractFactory("GemSale",{
          libraries: {
            IterableArrayWithoutDuplicateKeys: iterableArrayWithoutDuplicateKeys.address,
          },
        });
    gemSale = await GemSale.deploy();
  });
  it("Should deploy gemSale", async function () {
    const minDepositWad = await gemSale.minDepositWad();
    const maxDepositWad = await gemSale.maxDepositWad();
    const hardcap = await gemSale.hardcap();
    const totalDeposits = await gemSale.totalDeposits();
    const startEpoch = await gemSale.startEpoch();
    const endEpoch = await gemSale.endEpoch();
    const totalDepositors = await gemSale.totalDepositors();
    expect(minDepositWad).to.eq(parseEther("0.1"));
    expect(maxDepositWad).to.eq(parseEther("3"));
    expect(hardcap).to.eq(parseEther("15"));
    expect(totalDeposits).to.eq(parseEther("0"));
    expect(startEpoch).to.eq(0);
    expect(endEpoch).to.eq(0);
    expect(totalDepositors).to.eq(0);
  });
  it("Should revert when time not set", async function () {
    await expect(gemSale.deposit()).to.be.revertedWith("GemSale: Not Open");
  });
  it("Should revert when start epoch is in future", async function () {
    const currentTime = (await time.latest()).toNumber();
    await gemSale.setWhenOpen(currentTime+3600,currentTime+3600);
    await expect(gemSale.deposit()).to.be.revertedWith("GemSale: Not Open");
  });
  it("Should revert when end epoch is in past", async function () {
    const currentTime = (await time.latest()).toNumber();
    await gemSale.setWhenOpen(currentTime-3600,currentTime-3600);
    await expect(gemSale.deposit()).to.be.revertedWith("GemSale: Not Open");
  });
  it("Should revert when paused", async function () {
    await gemSale.pause();
    await expect(gemSale.deposit()).to.be.revertedWith("Pausable: paused");
  });
  it("Should revert when under minDepositWad", async function () {
    await gemSale.unpause();
    const currentTime = (await time.latest()).toNumber();
    await gemSale.setWhenOpen(currentTime-3600,currentTime+3600);
    await expect(gemSale.deposit({value:parseEther("0.01")})).to.be.revertedWith("GemSale: Deposit too small");
  });
  it("Should revert when over maxDepositWad", async function () {
    await expect(gemSale.deposit({value:parseEther("3.01")})).to.be.revertedWith("GemSale: Deposit too large");
  });
});