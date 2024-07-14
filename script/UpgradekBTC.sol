// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {kBTC} from "../src/kBTC.sol";
import {BaseDeployer} from "./BaseDeployer.s.sol";

/* solhint-disable no-console*/
import {console2} from "forge-std/console2.sol";

contract UpgradekBTC is Script, BaseDeployer {
    kBTC private wrappedProxy;

    /// @dev Upgrade contracts on testnet.
    function upgradeTestnet() external setEnvUpgrade(Cycle.Test) {
        Chains[] memory upgradeForks = new Chains[](2);

        upgradeForks[0] = Chains.ArbitrumSepolia;
        upgradeForks[1] = Chains.BscTest;

        createUpgradeMultichain(upgradeForks);
    }

    /// @dev Upgrade contracts on selected chains.
    /// @param upgradeForks The chains to upgrade.
    /// @param cycle The development cycle to set env variables (dev, test, prod).
    function upgradeSelectedChains(Chains[] calldata upgradeForks, Cycle cycle) external setEnvUpgrade(cycle) {
        createUpgradeMultichain(upgradeForks);
    }

    /// @dev Helper to iterate over chains and select forks.
    /// @param upgradeForks The chains to upgrade.
    function createUpgradeMultichain(Chains[] memory upgradeForks) private {
        for (uint256 i; i < upgradeForks.length;) {
            console2.log("Upgrading Counter on fork: ", uint256(upgradeForks[i]));

            createSelectFork(upgradeForks[i]);

            chainUpgrade();

            unchecked {
                ++i;
            }
        }
    }

    /// @dev Perform uprade on selected chain.
    function chainUpgrade() private broadcast(deployerPrivateKey) {
        //solhint-disable-next-line no-unused-vars
        kBTC impl = new kBTC();

        wrappedProxy = kBTC(proxyCounterAddress);

        wrappedProxy.upgradeTo(address(impl));
    }
}
