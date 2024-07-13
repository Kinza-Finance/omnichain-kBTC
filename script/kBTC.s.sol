// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import {BaseDeployer} from "./BaseDeployer.s.sol";
import {kBTC} from "../src/kBTC.sol";
import {OFT} from "../src/OFT.sol";
import {UUPSProxy} from "../src/UUPSProxy.sol";

contract DeploykBTC is Script, BaseDeployer {
    address private create2addrCounter;
    address private create2addrProxy;

    kBTC private wrappedProxy;

    struct LayerZeroChainDeployment {
        Chains chain;
        address endpoint;
    }

    LayerZeroChainDeployment[] private targetChains;

    function setUp() public {
        // Endpoint configuration from: https://docs.layerzero.network/contracts/endpoint-addresses
        targetChains.push(LayerZeroChainDeployment(Chains.Sepolia, 0x464570adA09869d8741132183721B4f0769a0287));
        targetChains.push(LayerZeroChainDeployment(Chains.Mumbai, 0x464570adA09869d8741132183721B4f0769a0287));
    }

    function run() public {}

    function deploykBTCTestnet(uint256 _counterSalt, uint256 _counterProxySalt) public setEnvDeploy(Cycle.Test) {
        counterSalt = bytes32(_counterSalt);
        counterProxySalt = bytes32(_counterProxySalt);

        createDeployMultichain();
    }

    /// @dev Helper to iterate over chains and select fork.
    function createDeployMultichain() private {
        address[] memory deployedContracts = new address[](targetChains.length);
        uint256[] memory forkIds = new uint256[](targetChains.length);

        for (uint256 i; i < targetChains.length;) {
            console2.log("Deploying to chain:", forks[targetChains[i].chain], "\n");

            uint256 forkId = createSelectFork(targetChains[i].chain);
            forkIds[i] = forkId;

            deployedContracts[i] = chainDeployCounter(targetChains[i].endpoint);

            ++i;
        }

        wireOApps(deployedContracts, forkIds);
    }

    /// @dev Function to perform actual deployment.
    function chainDeployCounter(address lzEndpoint)
        private
        computeCreate2(counterSalt, counterProxySalt, lzEndpoint)
        broadcast(deployerPrivateKey)
        returns (address deployedContract)
    {
        kBTC kbtc = new kBTC{salt: counterSalt}();

        require(create2addrCounter == address(kbtc), "Implementation address mismatch");

        console2.log("kBTC address:", address(kbtc), "\n");

        proxyCounter = new UUPSProxy{salt: counterProxySalt}(
            address(kbtc), abi.encodeWithSelector(OFT.initialize.selector, "Kinza Babylon Staked BTC", "kBTC", lzEndpoint, ownerAddress)
        );

        proxyCounterAddress = address(proxyCounter);

        require(create2addrProxy == proxyCounterAddress, "Proxy address mismatch");

        wrappedProxy = kBTC(proxyCounterAddress);

        require(wrappedProxy.owner() == ownerAddress, "Owner role mismatch");

        console2.log("kBTC Proxy address:", address(proxyCounter), "\n");

        return address(proxyCounter);
    }

    /// @dev Compute the CREATE2 addresses for contracts (proxy, kbtc).
    /// @param saltCounter The salt for the kbtc contract.
    /// @param saltProxy The salt for the proxy contract.
    modifier computeCreate2(bytes32 saltCounter, bytes32 saltProxy, address lzEndpoint) {
        create2addrCounter = vm.computeCreate2Address(saltCounter, hashInitCode(type(kBTC).creationCode));

        create2addrProxy = vm.computeCreate2Address(
            saltProxy,
            hashInitCode(
                type(UUPSProxy).creationCode,
                abi.encode(
                    create2addrCounter, abi.encodeWithSelector(OFT.initialize.selector, "Kinza Babylon Staked BTC", "kBTC", lzEndpoint, ownerAddress)
                )
            )
        );

        _;
    }
}
