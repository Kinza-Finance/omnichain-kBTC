// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import {BaseDeployer} from "./BaseDeployer.s.sol";
import {kBTC} from "../src/kBTC.sol";
import {OFT} from "../src/OFT.sol";
import {UUPSProxy} from "../src/UUPSProxy.sol";

contract DeploykBTC is Script, BaseDeployer {
    address private kbtccreate2addrkBTC;
    address private create2addrProxy;

    kBTC private wrappedProxy;

    struct LayerZeroChainDeployment {
        Chains chain;
        address endpoint;
    }

    LayerZeroChainDeployment[] private targetChains;

    function setUp() public {
        // Endpoint configuration from: https://docs.layerzero.network/contracts/endpoint-addresses
        // targetChains.push(LayerZeroChainDeployment(Chains.Ethereum, 0x1a44076050125825900e736c501f859c50fE728c));
        // targetChains.push(LayerZeroChainDeployment(Chains.Bsc, 0x1a44076050125825900e736c501f859c50fE728c));
        // targetChains.push(LayerZeroChainDeployment(Chains.Opbnb, 0x1a44076050125825900e736c501f859c50fE728c));
         targetChains.push(LayerZeroChainDeployment(Chains.Mantle, 0x1a44076050125825900e736c501f859c50fE728c));
        //targetChains.push(LayerZeroChainDeployment(Chains.MantleSepolia, 0x6EDCE65403992e310A62460808c4b910D972f10f));
        
    }

    function run() public {}


    function deploykBTCProd(uint256 _kbtcSalt, uint256 _proxySalt) public setEnvDeploy(Cycle.Prod) {
        salt = bytes32(_kbtcSalt);
        proxySalt = bytes32(_proxySalt);

        createDeployMultichain();
    }

    function deploykBTCTestnet(uint256 _kbtcSalt, uint256 _proxySalt) public setEnvDeploy(Cycle.Test) {
        salt = bytes32(_kbtcSalt);
        proxySalt = bytes32(_proxySalt);

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

            deployedContracts[i] = chainDeploy(targetChains[i].endpoint);

            ++i;
        }

        wireOApps(deployedContracts, forkIds);
    }

    /// @dev Function to perform actual deployment.
    function chainDeploy(address lzEndpoint)
        private
        computeCreate2(salt, proxySalt, lzEndpoint)
        broadcast(deployerPrivateKey)
        returns (address deployedContract)
    {
        kBTC kbtc = new kBTC{salt: salt}();

        require(kbtccreate2addrkBTC == address(kbtc), "Implementation address mismatch");

        console2.log("kBTC address:", address(kbtc), "\n");

        proxy = new UUPSProxy{salt: proxySalt}(
            address(kbtc), abi.encodeWithSelector(OFT.initialize.selector, "Kinza Babylon Staked BTC", "kBTC", lzEndpoint, ownerAddress)
        );

        proxyAddress = address(proxy);

        require(create2addrProxy == proxyAddress, "Proxy address mismatch");

        wrappedProxy = kBTC(proxyAddress);

        require(wrappedProxy.owner() == ownerAddress, "Owner role mismatch");

        console2.log("kBTC Proxy address:", address(proxy), "\n");

        return address(proxy);
    }

    /// @dev Compute the CREATE2 addresses for contracts (proxy, kbtc).
    /// @param saltCounter The salt for the kbtc contract.
    /// @param saltProxy The salt for the proxy contract.
    modifier computeCreate2(bytes32 saltCounter, bytes32 saltProxy, address lzEndpoint) {
        kbtccreate2addrkBTC = vm.computeCreate2Address(saltCounter, hashInitCode(type(kBTC).creationCode));

        create2addrProxy = vm.computeCreate2Address(
            saltProxy,
            hashInitCode(
                type(UUPSProxy).creationCode,
                abi.encode(
                    kbtccreate2addrkBTC, abi.encodeWithSelector(OFT.initialize.selector, "Kinza Babylon Staked BTC", "kBTC", lzEndpoint, ownerAddress)
                )
            )
        );

        _;
    }
}
