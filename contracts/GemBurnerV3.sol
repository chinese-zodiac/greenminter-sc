// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits & Kevin
// Accepts BNB, buys and burns GEM.
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "./interfaces/IAmmRouter02.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/ICzusdGateV2.sol";

contract GemBurnerV3 is Ownable, KeeperCompatibleInterface {
    using Address for address payable;

    ERC20PresetFixedSupply public gemToken =
        ERC20PresetFixedSupply(0x701F1ed50Aa5e784B8Fb89d1Ba05cCCd627839a7);
    uint256 public burnTriggerWad = 0.1 ether;
    IAmmRouter02 public router =
        IAmmRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    ICzusdGateV2 public czusdGate =
        ICzusdGateV2(0xe3CB4dB558fB7BaF59eC71F5B178be02726ab265);

    address public czusd = address(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70);

    constructor() Ownable() {
        IERC20(czusd).approve(address(router), type(uint256).max);
    }

    receive() external payable {}

    function setBurnTriggerWard(uint256 _to) external onlyOwner {
        burnTriggerWad = _to;
    }

    function canBurn() public view returns (bool) {
        return address(this).balance >= burnTriggerWad;
    }

    function checkUpkeep(
        bytes calldata
    )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = canBurn();
    }

    function performUpkeep(bytes calldata) external override {
        czusdGate.sellBnbForCzusd{value: address(this).balance}(address(this));

        address[] memory path = new address[](2);

        path[0] = address(czusd);
        path[1] = address(gemToken);
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            IERC20(czusd).balanceOf(address(this)), //amountin
            0,
            path, //address[] calldata path,
            address(this), //address to,
            block.timestamp //uint256 deadline
        );
        gemToken.burn(gemToken.balanceOf(address(this)));
    }

    function recoverERC20(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function withdraw(address payable _to) external onlyOwner {
        _to.sendValue(address(this).balance);
    }
}
