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

contract GemBurner is Ownable, KeeperCompatibleInterface {
    bytes32 public constant PROJECT_OWNER = keccak256("PROJECT_OWNER");
    using Address for address payable;

    ERC20PresetFixedSupply public gemToken;
    uint256 public burnTriggerWad;
    IAmmRouter02 public router;

    constructor(
        ERC20PresetFixedSupply _gemToken,
        uint256 _burnTriggerWad,
        IAmmRouter02 _router,
        address _admin
    ) Ownable() {
        gemToken = _gemToken;
        burnTriggerWad = _burnTriggerWad;
        router = _router;
        transferOwnership(_admin);
    }

    receive() external payable {}

    function setBurnTriggerWard(uint256 _to) external onlyOwner {
        burnTriggerWad = _to;
    }

    function canBurn() public view returns (bool) {
        return address(this).balance >= burnTriggerWad;
    }

    function checkUpkeep(bytes calldata)
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = canBurn();
    }

    function performUpkeep(bytes calldata) external override {
        address[] memory path = new address[](4);
        path[0] = router.WETH(); //WBNB
        path[1] = address(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); //BUSD
        path[2] = address(0xE68b79e51bf826534Ff37AA9CeE71a3842ee9c70); //CZUSD
        path[3] = address(gemToken); //GEM
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: address(this).balance
        }(
            0, //uint256 amountOutMin,
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
