// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        (, , address VrfCoordinator, , , , ) = helperConfig.activeConfig();
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

contract FundSubscription is Script {
    uint96 public constant FUND_AMOUNT = 3 ether;

    function FundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address VrfCoordinator,
            ,
            uint64 subId,
            ,
            address link
        ) = helperConfig.activeConfig();
        fundSubScription(VrfCoordinator, subId, link);
    }

    function fundSubScription(
        address VrfCoordinator,
        uint64 subId,
        address link
    ) internal {
        console.log("Funding subId: ", subId);
        console.log("VrfCoordinator: ", VrfCoordinator);
        console.log("Funding link token: ", link);
        if (block.chainid == 31337) {
            vm.startBroadcast();
            VRFCoordinatorV2Mock(VrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast();
            LinkToken(link).transferAndCall(
                VrfCoordinator,
                FUND_AMOUNT,
                abi.encode(subId)
            );
            vm.stopBroadcast();
        }
    }

    function run() external {
        FundSubscriptionUsingConfig();
    }
}
