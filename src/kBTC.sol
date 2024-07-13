// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {OFT} from "./OFT.sol";
import {SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

// custom kinza-babylon-staking BTC logic
contract kBTC is OFT {

    uint256 public rate = 1e18;

    address public aggregator;

    event RelayToBTCAddress(uint256 amount, string btcAddress, uint256 rate);
    event NewAggregator(address newAggregator);
    event NewRate(uint256 newRate);
    event NewSlash(uint256 newRate);

    modifier onlyAggregator() {
        require(msg.sender == aggregator, "Access Control");
        _;
    }

    function updateAggregator(address newAggregator) external onlyOwner {
        aggregator = newAggregator;
        emit NewAggregator(newAggregator);
    }
    function mint(address to, uint256 amount) external onlyAggregator {
        _mint(to, amount);
    }

    // when users burn the token we would send the same amount * rate, back to the specified btc address
    // if the btc address is in a wrong format we would need the user to contact us and provider proof of the evm address
    function burn(uint256 amount, string memory btcAddress) external {
        _burn(msg.sender, amount);

        emit RelayToBTCAddress(amount, btcAddress, rate);
    }

    // this is the rate of kbBTC toward the underlying amount of BTC backed by the BTC staking positions in native network
    // on extreme occasion (where slashing happens), the rate is reduced.
    function updateYield(uint256 newRate) external onlyAggregator {
        require(newRate > rate, "yield should be positive");
        rate = newRate;
        emit NewRate(newRate);
    }

    function reflectSlash(uint256 newRate)  external onlyAggregator {
        require(newRate < rate, "slash should be positive");
        rate = newRate;
        emit NewSlash(newRate);
    }

    // this is a function to remove someone's balance out of supply, only called in emergency
    function emergencyBurn(address burnee, uint256 amount) external onlyOwner {
         _burn(burnee, amount);
    }

}
