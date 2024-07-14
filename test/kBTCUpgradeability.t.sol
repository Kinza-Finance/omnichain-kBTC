// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";

import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import {MessagingFee, MessagingReceipt} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OFT} from "../src/OFT.sol";
import {kBTC} from "../src/kBTC.sol";
import {kBTCV2} from "./mocks/kBTCV2.sol";
import {UUPSProxy} from "../src/UUPSProxy.sol";
import {ProxyTestHelper} from "./utils/ProxyTestHelper.sol";

contract UpgradeabilityTest is ProxyTestHelper {
    using OptionsBuilder for bytes;

    uint32 aEid = 1;
    uint32 bEid = 2;

    kBTC private kBTCImplementation;

    kBTC public kbtc;
    kBTC public bkbtc;

    address private user = address(0x1);

    address private nonAdminAccount = makeAddr("nonAdminAccount");

    function setUp() public virtual override {
        super.setUp();

        setUpEndpoints(2, LibraryType.UltraLightNode);

        kbtc = kBTC(
            _deployOAppProxyGeneralized(
                type(kBTC).creationCode,
                abi.encodeWithSelector(OFT.initialize.selector, "kBTC", "kBTC", address(endpoints[aEid]), address(this))
            )
        );

        bkbtc = kBTC(
            _deployOAppProxyGeneralized(
                type(kBTC).creationCode,
                abi.encodeWithSelector(OFT.initialize.selector, "kBTC", "kBTC", address(endpoints[bEid]), address(this))
            )
        );

        // config and wire the ofts
        address[] memory ofts = new address[](2);
        ofts[0] = address(kbtc);
        ofts[1] = address(bkbtc);
        this.wireOApps(ofts);

        kBTCImplementation = kBTC(kbtc.getImplementation());
    }

    function test_setUp_alreadyInitialized_asProxy_reverts() public {
        vm.expectRevert("Initializable: contract is already initialized");
        kbtc.initialize("Kinza Babylon Staked BTC", "kBTC", address(0), nonAdminAccount);
    }

    function test_setUp_alreadyInitialized_asImpl_reverts() public {
        vm.expectRevert("Initializable: contract is already initialized");
        kBTCImplementation.initialize("Kinza Babylon Staked BTC", "kBTC", address(0), nonAdminAccount);
    }

    function test_setUp_succeeds() public {
        address expectedOwner = address(this);

        assertEq(kbtc.owner(), expectedOwner, "Owner should be set");
        assertEq(kbtc.totalSupply(), 0, "total supply should be 0");
        assertEq(kbtc.getImplementation(), address(kBTCImplementation), "Implementation should be set");
    }

    function test_upgradeTo_notAdmin_reverts() public {
        kBTCV2 impl2 = new kBTCV2();
        vm.prank(nonAdminAccount);

        vm.expectRevert("Ownable: caller is not the owner");
        kbtc.upgradeTo(address(impl2));
    }

    function test_upgradeTo_succeeds() public {
        kBTCV2 impl2 = new kBTCV2();
        address expectedOwner = address(this);
        uint256 amount = 1e18;

        assertEq(bkbtc.totalSupply(), 0, "b network supply should be persisted after the upgrade");
        assertEq(kbtc.owner(), expectedOwner, "Owner should be correctly set before upgrade");
    
        kbtc.upgradeTo(address(impl2));

        assertEq(kbtc.getImplementation(), address(impl2), "Implementation should be upgraded");
        assertEq(kbtc.owner(), expectedOwner, "Owner should be correctly set before upgrade");

        // State persists
        assertEq(bkbtc.totalSupply(), 0, "b network supply should be persisted after the upgrade");
        assertEq(bkbtc.owner(), expectedOwner, "Owner should be set correctly after the upgrade");
        // test and assert send
        send_oft_a_to_b(amount);

    }

    function send_oft_a_to_b(uint256 tokensToSend) public {
        // mint it on aeid
        deal(address(kbtc) , user, tokensToSend);
        SendParam memory sendParam = SendParam(bEid, addressToBytes32(user), tokensToSend, tokensToSend);
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200000, 0);
        MessagingFee memory fee = kbtc.quoteSend(sendParam, options, false, "", "");

        assertEq(kbtc.balanceOf(user), tokensToSend);
        assertEq(bkbtc.balanceOf(user), 0);

        vm.prank(user);
        // deal some ether
        vm.deal(user, 1e18);
        kbtc.send{value: fee.nativeFee}(sendParam, options, fee, payable(address(this)), "", "");
        verifyPackets(bEid, addressToBytes32(address(bkbtc)));

        assertEq(kbtc.balanceOf(user), 0);
        assertEq(bkbtc.balanceOf(user), tokensToSend);
    }


    // required for test helper to know how to initialize the OApp
    function _deployOAppProxy(address _endpoint, address _owner, address implementationAddress)
        internal
        override
        returns (address proxyAddress)
    {
        UUPSProxy proxy =
            new UUPSProxy(implementationAddress, abi.encodeWithSelector(OFT.initialize.selector, "Kinza Babylon Staked BTC", "kBTC", _endpoint, _owner));
        proxyAddress = address(proxy);
    }
}
