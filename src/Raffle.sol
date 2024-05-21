// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external - can only be called from outside the contract
// public - can be accessed by everyone including other functions in the contract
// internal - can be accessed by the contract and any contract the inherits it
//      - note that the inherited contract calls its own version of the function and not the original function itself
// private - can only be accessed by the other functions in the contract
// view & pure functions

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    // ERRORS //
    error Raffle__SendMoreThanEntranceFee();
    error Raffle__CurrentRaffleHasExpired();
    error Raffle__failedToSendPrize();
    error Raffle__CurrentRaffleIsCalculating();
    error Raffle__UpKeepNotNeeded(
        uint256 balance,
        uint256 players,
        uint256 state
    );

    // TYPES //
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }

    // STATE VARIABLES //
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    VRFCoordinatorV2Interface private immutable i_VrfCoordinator;
    uint256 private immutable i_entranceFee;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subScriptionId;
    uint32 private immutable i_callbackGasLimit;
    // @dev durration of the raffles in seconds
    uint256 private immutable i_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_RecentWinner;
    RaffleState private s_raffleState;

    // EVENTS //
    event EnteredRaffle(address indexed player);
    event WinnerSelected(address indexed winner);
    event RequestedRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address VrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(VrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimeStamp = block.timestamp;
        i_VrfCoordinator = VRFCoordinatorV2Interface(VrfCoordinator);
        i_gasLane = gasLane;
        i_subScriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
    }

    function enterRaffle() external payable {
        if (msg.value < i_entranceFee) {
            revert Raffle__SendMoreThanEntranceFee();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__CurrentRaffleIsCalculating();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
        bool raffleIsOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded =
            timeHasPassed &&
            raffleIsOpen &&
            hasBalance &&
            hasPlayers;

        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle__UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }

        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_VrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subScriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 winnerIndex = randomWords[0] % s_players.length;
        address payable winner = s_players[winnerIndex];
        s_RecentWinner = winner;

        s_raffleState = RaffleState.OPEN;
        s_lastTimeStamp = block.timestamp;
        s_players = new address payable[](0);
        emit WinnerSelected(winner);

        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__failedToSendPrize();
        }
    }

    // GETTERS //

    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 index) external view returns (address) {
        return s_players[index];
    }
}
