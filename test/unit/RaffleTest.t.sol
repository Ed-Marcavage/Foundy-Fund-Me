// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

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
    address link;

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
            callbackGasLimit,
            link,

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
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
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

    /////////////////
    // checkUpkeep //
    /////////////////

    function testcheckUpkeepReturnsFalseIfNoBalance() public {
        vm.warp(block.timestamp + interval + 1); //Sets block.timestamp
        vm.roll(block.number + 1); //Sets block.number.

        (bool upkeepNeeded, ) = raffle.checkUpkeep("0x0");
        assert(!upkeepNeeded);
    }

    function testcheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); //Sets block.timestamp
        vm.roll(block.number + 1); //Sets block.number.
        raffle.performUpkeep("0x0");

        (bool upkeepNeeded, ) = raffle.checkUpkeep("0x0");
        assert(!upkeepNeeded);
    }

    function testcheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval - 10); //Sets block.timestamp
        vm.roll(block.number + 1); //Sets block.number.

        (bool upkeepNeeded, ) = raffle.checkUpkeep("0x0");
        assert(!upkeepNeeded);
    }

    function testcheckUpkeepReturnsTrueIfAllConditionsMet() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); //Sets block.timestamp
        vm.roll(block.number + 1); //Sets block.number.

        (bool upkeepNeeded, ) = raffle.checkUpkeep("0x0");
        assert(upkeepNeeded);
    }

    ///////////////////
    // performUpkeep //
    ///////////////////

    function testPreformUpkeepCanOnlyRunIfCheckUpkeepReturnsTrue() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); //Sets block.timestamp
        vm.roll(block.number + 1); //Sets block.number.
        raffle.performUpkeep("0x0");
    }

    function testPreformUpKeepRevertsIfCheckUpKeepisFalse() public {
        uint256 currentBalance = 0;
        uint256 playerCount = 0;
        uint256 raffleState = uint256(Raffle.RaffleState.OPEN);
        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpKeepNotNeeded.selector,
                currentBalance,
                playerCount,
                raffleState
            )
        );
        raffle.performUpkeep("0x0");
    }

    modifier raffleEnteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1); //Sets block.timestamp
        vm.roll(block.number + 1); //Sets block.number.
        _;
    }

    function testRequestedRaffleWinnerIsEmitted()
        public
        raffleEnteredAndTimePassed
    {
        vm.recordLogs(); // Tells the VM to start recording all the emitted events. To access them, use getRecordedLogs
        raffle.performUpkeep("0x0");
        Vm.Log[] memory log = vm.getRecordedLogs();
        bytes32 requestId = log[1].topics[1];

        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(raffleState == Raffle.RaffleState.CALCULATING);
        assert(requestId > 0);
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testFulfillRandomWords(uint256 randomRequestId) public skipFork {
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(VrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testendTwoEnd() public raffleEnteredAndTimePassed skipFork {
        // uint 256 for additional entrants and starting index
        uint256 additionalEntrants = 5;
        uint256 startingIndex = 1;
        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address player = makeAddr("player"); // or could do address(uint160(i))
            hoax(player, STARTING_BALANCE); // hoax is prank + deal
            raffle.enterRaffle{value: entranceFee}();
        }

        uint256 prize = entranceFee * (additionalEntrants + 1);
        vm.recordLogs(); // Tells the VM to start recording all the emitted events. To access them, use getRecordedLogs
        raffle.performUpkeep("0x0");
        Vm.Log[] memory log = vm.getRecordedLogs();
        bytes32 requestId = log[1].topics[1];

        uint256 prevTimeStamp = raffle.getLastTimeStamp();

        VRFCoordinatorV2Mock(VrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );

        assert(uint256(raffle.getRaffleState()) == 0);
        assert(raffle.getLastTimeStamp() > prevTimeStamp);
        assert(raffle.getRecentWinner() != address(0));
        assert(raffle.getLengthOfPlayers() == 0);
        console.log("STARTING_BALANCE + prize: ", STARTING_BALANCE + prize);
        //10060000000000000000
        console.log("Balance: ", address(raffle.getRecentWinner()).balance);
        //10050000000000000000
        assert(
            address(raffle.getRecentWinner()).balance ==
                STARTING_BALANCE + prize - entranceFee
        );
    }
}
