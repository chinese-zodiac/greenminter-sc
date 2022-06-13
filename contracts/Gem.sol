// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits & Kevin
// Burns CZUSD, tracks locked liquidity, trades to BNB and sends to Kevin for running green miners
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./czodiac/CZUsd.sol";
import "./libs/AmmLibrary.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/IAmmPair.sol";
import "./interfaces/IAmmRouter02.sol";

contract Gem is ERC20PresetFixedSupply, AccessControlEnumerable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    bytes32 public constant MANAGER = keccak256("MANAGER");

    uint256 public burnBPS = 1000;
    mapping(address => bool) public isExempt;

    IAmmPair public ammCzusdPair;
    IAmmRouter02 public ammRouter;
    CZUsd public czusd;

    uint256 public baseCzusdLocked;
    uint256 public totalCzusdSpent;

    constructor(
        CZUsd _czusd,
        IAmmRouter02 _ammRouter,
        IAmmFactory _factory,
        uint256 _baseCzusdLocked
    ) ERC20PresetFixedSupply("GreenMiner", "GEM", 200000 ether, msg.sender) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MANAGER, msg.sender);

        setCzusd(_czusd);
        setAmmRouter(_ammRouter);
        setBaseCzusdLocked(_baseCzusdLocked);

        ammCzusdPair = IAmmPair(
            _factory.createPair(address(this), address(czusd))
        );

        setIsExempt(msg.sender, true);
    }

    function lockedCzusd() public view returns (uint256 lockedCzusd_) {
        bool czusdIsToken0 = ammCzusdPair.token0() == address(czusd);
        (uint112 reserve0, uint112 reserve1, ) = ammCzusdPair.getReserves();
        uint256 lockedLP = ammCzusdPair.balanceOf(address(this));
        uint256 totalLP = ammCzusdPair.totalSupply();

        uint256 lockedLpCzusdBal = ((czusdIsToken0 ? reserve0 : reserve1) *
            lockedLP) / totalLP;
        uint256 lockedLpGemBal = ((czusdIsToken0 ? reserve1 : reserve0) *
            lockedLP) / totalLP;

        if (lockedLpGemBal == totalSupply()) {
            lockedCzusd_ = lockedLpCzusdBal;
        } else {
            lockedCzusd_ =
                lockedLpCzusdBal -
                (
                    AmmLibrary.getAmountOut(
                        totalSupply() - lockedLpGemBal,
                        lockedLpGemBal,
                        lockedLpCzusdBal
                    )
                );
        }
    }

    function setIsExempt(address _for, bool _to) public onlyRole(MANAGER) {
        isExempt[_for] = _to;
    }

    function recoverERC20(address tokenAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20(tokenAddress).transfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }

    function withdraw(address payable _to)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _to.sendValue(address(this).balance);
    }

    function setBaseCzusdLocked(uint256 _to)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        baseCzusdLocked = _to;
    }

    function setAmmRouter(IAmmRouter02 _to)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        ammRouter = _to;
    }

    function setCzusd(CZUsd _to) public onlyRole(DEFAULT_ADMIN_ROLE) {
        czusd = _to;
    }
}