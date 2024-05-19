// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address VrfCoordinator, , , ) = helperConfig.activeConfig();
        return createSubscription(VrfCoordinator);
    }

    function createSubscription(
        address VrfCoordinator
    ) public returns (uint64) {
        console.log("Creating a subscription on chain ID: ", block.chainid);
        // Create a subscription
        vm.startBroadcast();
        uint64 subId = VRFCoordinatorV2Mock(VrfCoordinator)
            .createSubscription();
        vm.stopBroadcast();
        console.log("Your Sub ID is: ", subId);
        return subId;
    }

    function run() external returns (uint64) {
        return CreateSubscriptionUsingConfig();
    }
}
