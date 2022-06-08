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

    uint256 public minDepositWad = 0.01 ether;
    uint256 public maxDepositWad = 10 ether;

    receive() external payable {
        deposit();
    }

    function deposit() public payable whenNotPaused {
        trackedAddresses.add(msg.sender);
        require(msg.value >= minDepositWad, "GemSale: Deposit too small");
        require(msg.value <= maxDepositWad, "GemSale: Deposit too large");
        depositedAmount[msg.sender] += msg.value;
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
}
