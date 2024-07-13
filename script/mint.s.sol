// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";

import "../src/offChainSignatureAggregator.sol";


contract MintScript is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        offChainSignatureAggregator agg = offChainSignatureAggregator(0xE764Dacc87E7C0902a4b1c80a246Fc290AadC151);
        //kbBTC token = kbBTC(0xBB9f85fB301F33513C6596Bc0B2EAB8A243a3Cee);
        offChainSignatureAggregator.Report memory report = offChainSignatureAggregator.Report(
            0xCc3fBD1ff6E1e2404D0210823C78ae74085b6235,
            0.0001 * 1e18,
            1
        );
        offChainSignatureAggregator.Signature[] memory _rs = new offChainSignatureAggregator.Signature[](1);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            deployerPrivateKey,
            keccak256(abi.encodePacked("\x19\x01", agg.DOMAIN_SEPARATOR(), agg.reportDigest(report)))
        );
        offChainSignatureAggregator.Signature memory rep = offChainSignatureAggregator.Signature({
            v: v,
            r: r,
            s: s
        });

        _rs[0] = rep;
        agg.mintBTC(report, _rs);
        vm.stopBroadcast(); 
    }
}
