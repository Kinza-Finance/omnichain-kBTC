// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";

import {OApp} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";

import {UUPSProxy} from "../src/UUPSProxy.sol";

// taken from: https://github.com/timurguvenkaya/foundry-multichain/blob/main/script/BaseDeployer.s.sol
/* solhint-disable max-states-count */
contract BaseDeployer is Script {
    UUPSProxy internal proxy;

    bytes32 internal proxySalt;
    bytes32 internal salt;

    uint256 internal deployerPrivateKey;

    address internal ownerAddress;
    address internal proxyAddress;

    enum Chains {
        OpbnbTest,
        Opbnb,
        Mantle,
        MantleSepolia,
        LocalGoerli,
        LocalFuji,
        LocalBSCTest,
        BscTest,
        ArbitrumSepolia,
        Ethereum,
        Bsc
    }

    enum Cycle {
        Dev,
        Test,
        Prod
    }

    /// @dev Mapping of chain enum to rpc url
    mapping(Chains chains => string rpcUrls) public forks;

    /// @dev environment variable setup for deployment
    /// @param cycle deployment cycle (dev, test, prod)
    modifier setEnvDeploy(Cycle cycle) {
        if (cycle == Cycle.Dev) {
            deployerPrivateKey = vm.envUint("LOCAL_DEPLOYER_KEY");
            ownerAddress = vm.envAddress("LOCAL_OWNER_ADDRESS");
        } else if (cycle == Cycle.Test) {
            deployerPrivateKey = vm.envUint("TEST_DEPLOYER_KEY");
            ownerAddress = vm.envAddress("TEST_OWNER_ADDRESS");
        } else {
            deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
            ownerAddress = vm.envAddress("OWNER_ADDRESS");
        }

        _;
    }

    /// @dev environment variable setup for upgrade
    /// @param cycle deployment cycle (dev, test, prod)
    modifier setEnvUpgrade(Cycle cycle) {
        if (cycle == Cycle.Dev) {
            deployerPrivateKey = vm.envUint("LOCAL_DEPLOYER_KEY");
            proxyAddress = vm.envAddress("LOCAL_COUNTER_PROXY_ADDRESS");
        } else if (cycle == Cycle.Test) {
            deployerPrivateKey = vm.envUint("TEST_DEPLOYER_KEY");
            proxyAddress = vm.envAddress("TEST_COUNTER_PROXY_ADDRESS");
        } else {
            deployerPrivateKey = vm.envUint("DEPLOYER_KEY");
            proxyAddress = vm.envAddress("COUNTER_PROXY_ADDRESS");
        }

        _;
    }

    /// @dev broadcast transaction modifier
    /// @param pk private key to broadcast transaction
    modifier broadcast(uint256 pk) {
        vm.startBroadcast(pk);

        _;

        vm.stopBroadcast();
    }

    constructor() {
        // Local
        forks[Chains.LocalGoerli] = "localGoerli";
        forks[Chains.LocalFuji] = "localFuji";
        forks[Chains.LocalBSCTest] = "localBSCTest";

        // Testnet
        forks[Chains.ArbitrumSepolia] = 'arbitriumsepolia';
        forks[Chains.OpbnbTest] = "opbnbtest";
        forks[Chains.MantleSepolia] = "mantlesepolia";
        forks[Chains.BscTest] = "bsctest";

        // Mainnet
        forks[Chains.Opbnb] = "opbnb";
        forks[Chains.Mantle] = "mantle";
        forks[Chains.Ethereum] = "ethereum";
        forks[Chains.Bsc] = "bsc";
    }

    function createFork(Chains chain) public {
        vm.createFork(forks[chain]);
    }

    function createSelectFork(Chains chain) public returns (uint256 forkId) {
        return vm.createSelectFork(forks[chain]);
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function wireOApps(address[] memory oapps, uint256[] memory forkIds) public {
        uint256 size = oapps.length;
        for (uint256 i = 0; i < size; i++) {
            OApp localOApp = OApp(payable(oapps[i]));
            for (uint256 j = 0; j < size; j++) {
                if (i == j) continue;
                vm.selectFork(forkIds[j]);
                OApp remoteOApp = OApp(payable(oapps[j]));
                uint32 remoteEid = (remoteOApp.endpoint()).eid();
                vm.selectFork(forkIds[i]);

                vm.startBroadcast(deployerPrivateKey);
                localOApp.setPeer(remoteEid, addressToBytes32(address(remoteOApp)));
                vm.stopBroadcast();
            }
        }
    }
}
