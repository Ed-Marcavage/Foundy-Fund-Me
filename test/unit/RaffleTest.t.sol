// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";

contract RaffleTest is Test {
    // EVENTS //
    event EnteredRaffle(address indexed player);

    Raffle raffle;
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address VrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player"); // Creates an address derived from the provided name.
    uint256 public constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        DeployRaffle deployRaffle = new DeployRaffle();
        (raffle, helperConfig) = deployRaffle.run();

        (
            entranceFee,
            interval,
            VrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        ) = helperConfig.activeConfig();
        vm.deal(PLAYER, STARTING_BALANCE); // Sends ether to the specified address
    }

    function testRaffleInitsInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertdsIfNotEnoughFunds() public {
        vm.prank(PLAYER); // Sets msg.sender to the specified address for the next call
        vm.expectRevert(Raffle.Raffle__SendMoreThanEntranceFee.selector);
        raffle.enterRaffle();
    }

    function testRaffleRevertdsIfCalculatingState() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); //Sets block.timestamp
        vm.roll(block.number + 1); //Sets block.number.
        raffle.performUpkeep("0x0");
        vm.expectRevert(Raffle.Raffle__CurrentRaffleIsCalculating.selector);
    }

    function testRaffleRecordsPlayer() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEmitsEventUponRaffleEntry() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle)); // checkData == un indexed parameter
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }
}
