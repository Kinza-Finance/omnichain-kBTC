// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import "../src/kBTC.sol";
import "../src/offChainSignatureAggregator.sol";


contract AggregatorScript is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address deployer = address(0xCc3fBD1ff6E1e2404D0210823C78ae74085b6235);
        kBTC proxy = kBTC(0x28e48a431BE3212566E895ce1962a7109BeF8731);
        offChainSignatureAggregator agg = new offChainSignatureAggregator(address(proxy));
        proxy.updateAggregator(address(agg));
        address[] memory _signers = new address[](2);
        _signers[0] = 0x658134107391bA91E2104519eA919d5889c5b42d;
        _signers[1] = 0xCc3fBD1ff6E1e2404D0210823C78ae74085b6235;
        bool[] memory _rights = new bool[](2);
        _rights[0] = true;
        _rights[1] = true;
        agg.setSigners(_signers, _rights);
        vm.stopBroadcast(); 
    }
}
