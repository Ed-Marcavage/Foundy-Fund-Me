// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {Test, console} from "forge-std/Test.sol";

/**
 * @title HelperConfig
 * @dev A contract that provides configuration options for different network environments.
 */
contract HelperConfig is Script {
    uint256 public constant ANVIL_KEY =
        0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6;

    struct networkConfig {
        uint256 entranceFee;
        uint256 interval;
        address VrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
        address link;
        uint256 deployerKey;
    }

    networkConfig public activeConfig;

    constructor() {
        if (block.chainid == 11155111) {
            activeConfig = getSepoliaEthConfig();
        } else {
            activeConfig = getOrCreateAnvilEthConfig();
        }
    }

    /**
     * @dev Returns the configuration for the Sepolia Ethereum network.
     * @return The network configuration.
     */
    function getSepoliaEthConfig() public view returns (networkConfig memory) {
        console.log("vm.envU Chain ID: ", vm.envUint("PRIVATE_KEY"));
        return
            networkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                VrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 500_000, // 500k gas
                link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
                deployerKey: vm.envUint("PRIVATE_KEY")
            });
    }

    /**
     * @dev Returns the configuration for the Anvil Ethereum network.
     * @return The network configuration.
     */
    function getOrCreateAnvilEthConfig() public returns (networkConfig memory) {
        if (activeConfig.VrfCoordinator != address(0)) {
            return activeConfig;
        }
        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrfCoordinator = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        return
            networkConfig({
                entranceFee: 0.01 ether,
                interval: 30,
                VrfCoordinator: address(vrfCoordinator),
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 500_000, // 500k gas
                link: address(link),
                deployerKey: ANVIL_KEY
            });
    }
}
