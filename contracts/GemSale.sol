// SPDX-License-Identifier: GPL-3.0
// Authored by Plastic Digits

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libs/IterableArrayWithoutDuplicateKeys.sol";

contract GemSale is Ownable, Pausable {
    using IterableArrayWithoutDuplicateKeys for IterableArrayWithoutDuplicateKeys.Map;
    using Address for address payable;

    IterableArrayWithoutDuplicateKeys.Map trackedAddresses;
    mapping(address => uint256) public depositedAmount;

    event Deposit(address, uint256);

    uint256 public minDepositWad = 0.1 ether;
    uint256 public maxDepositWad = 3 ether;
    uint256 public hardcap = 15 ether;
    uint256 public totalDeposits;

    uint256 public startEpoch;
    uint256 public endEpoch;

    modifier whenOpen() {
        require(
            block.timestamp <= endEpoch && block.timestamp >= startEpoch,
            "GemSale: Not Open"
        );
        _;
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable whenNotPaused whenOpen {
        require(totalDeposits + msg.value <= hardcap, "GemSale: Over hardcap");
        require(msg.value >= minDepositWad, "GemSale: Deposit too small");
        require(msg.value <= maxDepositWad, "GemSale: Deposit too large");
        trackedAddresses.add(msg.sender);
        depositedAmount[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(address payable _to) external onlyOwner {
        _to.sendValue(address(this).balance);
    }

    function totalDepositors() external view returns (uint256) {
        return trackedAddresses.size();
    }

    function getDepositorFromIndex(uint256 _i) external view returns (address) {
        return trackedAddresses.getKeyAtIndex(_i);
    }

    function getIndexFromDepositor(address _depositor)
        external
        view
        returns (int256)
    {
        return trackedAddresses.getIndexOfKey(_depositor);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setMinDepositWad(uint256 _to) external onlyOwner {
        minDepositWad = _to;
    }

    function setMaxDepositWad(uint256 _to) external onlyOwner {
        maxDepositWad = _to;
    }

    function setWhenOpen(uint256 _startEpoch, uint256 _endEpoch)
        external
        onlyOwner
    {
        startEpoch = _startEpoch;
        endEpoch = _endEpoch;
    }

    function recoverERC20(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(
            _msgSender(),
            IERC20(tokenAddress).balanceOf(address(this))
        );
    }
}
