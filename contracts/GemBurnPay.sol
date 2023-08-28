// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "./Gem.sol";
import "./czodiac/CZUsd.sol";

contract GemBurnPay is KeeperCompatibleInterface, Ownable {
    uint256 sanityLimit = 500 ether;
    Gem public gem = Gem(0x701F1ed50Aa5e784B8Fb89d1Ba05cCCd627839a7);
    uint256 public lockedCzusdTriggerLevel = 100 ether;
    CZUsd public czusd = CZUsd(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);
    uint256 public totalCzusdSpent;
    address public devWallet;

    function availableWadToSend() public view returns (uint256) {
        return
            gem.lockedCzusd() -
            gem.baseCzusdLocked() -
            gem.totalCzusdSpent() -
            totalCzusdSpent;
    }

    function isOverTriggerLevel() public view returns (bool) {
        return lockedCzusdTriggerLevel <= availableWadToSend();
    }

    function checkUpkeep(
        bytes calldata
    ) public view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = isOverTriggerLevel();
    }

    function performUpkeep(bytes calldata) external override {
        uint256 wadToSend = availableWadToSend();
        totalCzusdSpent += wadToSend;
        require(wadToSend < sanityLimit, "Above sanity limit");
        czusd.mint(devWallet, wadToSend);
    }

    function recoverERC20(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function setDevWallet(address _to) public onlyOwner {
        devWallet = _to;
    }

    function setLockedCzusdTriggerLevel(uint256 _to) public onlyOwner {
        lockedCzusdTriggerLevel = _to;
    }

    function setSanityLimit(uint256 _to) public onlyOwner {
        sanityLimit = _to;
    }
}
