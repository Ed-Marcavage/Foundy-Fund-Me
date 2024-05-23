// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint64) {
        HelperConfig helperConfig = new HelperConfig();
        // helper config conditionally sets the config based on the chain ID
        (, , address VrfCoordinator, , , , , uint256 deployerKey) = helperConfig
            .activeConfig();
        return createSubscription(VrfCoordinator, deployerKey);
    }

    function createSubscription(
        address VrfCoordinator,
        uint256 deployerKey
    ) public returns (uint64) {
        console.log("Creating a subscription on chain ID: ", block.chainid);
        // Create a subscription
        vm.startBroadcast(deployerKey);
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
    uint96 public constant FUND_AMOUNT = 0.01 ether;

    function FundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address VrfCoordinator,
            ,
            uint64 subId,
            ,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeConfig();
        fundSubScription(VrfCoordinator, subId, link, deployerKey);
    }

    function fundSubScription(
        address VrfCoordinator,
        uint64 subId,
        address link,
        uint256 deployerKey
    ) public {
        console.log("Funding subId: ", subId);
        console.log("VrfCoordinator: ", VrfCoordinator);
        console.log("Funding link token: ", link);
        // if we are on the local chain, we can use the mock
        if (block.chainid == 31337) {
            vm.startBroadcast(deployerKey);
            VRFCoordinatorV2Mock(VrfCoordinator).fundSubscription(
                subId,
                FUND_AMOUNT
            );
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(deployerKey);
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

contract AddConsumer is Script {
    function addConsumer(
        address raffle,
        address VrfCoordinator,
        uint64 subId,
        uint256 DeployerKey
    ) public {
        console.log("Adding consumer to raffle: ", raffle);
        console.log("VrfCoordinator: ", VrfCoordinator);
        console.log("SubId: ", subId);
        vm.startBroadcast(DeployerKey);
        VRFCoordinatorV2Mock(VrfCoordinator).addConsumer(subId, raffle);
        vm.stopBroadcast();
    }

    function addConsumerUsingConfig(address raffle) public {
        HelperConfig helperConfig = new HelperConfig();
        (
            ,
            ,
            address VrfCoordinator,
            ,
            uint64 subId,
            ,
            ,
            uint256 DeployerKey
        ) = helperConfig.activeConfig();
        addConsumer(raffle, VrfCoordinator, subId, DeployerKey);
    }

    function run() external {
        address raffle = DevOpsTools.get_most_recent_deployment(
            "Raffle",
            block.chainid
        );
        addConsumerUsingConfig(raffle);
    }
}
