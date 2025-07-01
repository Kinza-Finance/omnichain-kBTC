// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {IOFT, SendParam, OFTReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";



contract AggregatorScript is Script {
    using OptionsBuilder for bytes;
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        address deployer = address(0xDE6A2451A4ACeb6D540Bd216578C84503639EbF1);
        IOFT proxy = IOFT(0x9356f6d95b8E109F4b7Ce3E49D672967d3B48383);
        // 40102 bsctest // 40231 arb sepolia
        uint32 dstEid = 30101;
        bytes32 to = bytes32(uint256(uint160(deployer)));
        uint256 tokensToSend = 0.0001 ether;
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        SendParam memory sendParam = SendParam(
            dstEid,
            to,
            tokensToSend,
            tokensToSend
        );
        MessagingFee memory fee = proxy.quoteSend(sendParam, options, false, "", "");

        proxy.send{ value: fee.nativeFee }(sendParam, options, fee, payable(address(this)), "", "");
        vm.stopBroadcast(); 
    }
}
