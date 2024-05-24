import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {Test, console} from "forge-std/Test.sol";

contract TestInteractions is Test {
    DeployRaffle deployRaffle;

    uint256 entranceFee;
    uint256 interval;
    address VrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;
    HelperConfig helperConfig;
    Raffle raffle;

    function setUp() external {
        deployRaffle = new DeployRaffle();
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
    }

    // test raffle contract has been deployed
    function testRaffleDeployed() public view {
        assert(address(raffle) != address(0));
    }
}
