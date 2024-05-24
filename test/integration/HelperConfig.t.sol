import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract TestInteractions is Test {
    HelperConfig helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address VrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;
    address link;

    function setUp() external {
        helperConfig = new HelperConfig();
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

    modifier skipLocal() {
        if (block.chainid == 31337) {
            return;
        }
        _;
    }

    // split testConfigValues into multiple tests
    function testEntranceFee() public view {
        assert(entranceFee == 0.01 ether);
    }

    function testInterval() public view {
        assert(interval == 30);
    }

    function testVrfCoordinator() public view skipLocal {
        assert(VrfCoordinator == 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625);
    }

    function testVrfCoordinatorAddressIsNotNullOnLocal() public view {
        assert(VrfCoordinator != address(0));
    }

    function testLinkAddressIsNotNullOnLocal() public view {
        assert(link != address(0));
    }

    function testGasLane() public view {
        assert(
            gasLane ==
                0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c
        );
    }

    function testSubscriptionId() public view {
        assert(subscriptionId == 0);
    }

    function testCallbackGasLimit() public view {
        assert(callbackGasLimit == 500_000);
    }

    function testLink() public view skipLocal {
        assert(link == 0x779877A7B0D9E8603169DdbD7836e478b4624789);
    }
}
