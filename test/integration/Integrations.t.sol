// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {CreateSubscription, FundSubscription, AddConsumer} from "../../script/Interactions.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {SubscriptionAPI} from "@chainlink/contracts/src/v0.8/vrf/dev/SubscriptionAPI.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";

/**
 * @dev The tests in this contract were made as an optional assignment for the Foundry Fundamentals Course of Cyfrin Updraft.
 * I made them in order to practice integration tests in Solidity. Therefore they are not for production and their validity is not guaranteed.
 */
contract Integrations is Test, CodeConstants {
    HelperConfig.NetworkConfig public config;
    uint256 public oldBalance;
    uint256 public constant FUND_AMOUNT = 3 ether; // 3 LINK
    HelperConfig public helperConfig;

    event SubscriptionFunded(uint256 indexed subId, uint256 oldBalance, uint256 newBalance);
    event SubscriptionConsumerAdded(uint256 indexed subId, address consumer);

    function setUp() external {
        helperConfig = new HelperConfig();
        // local -> deploy mocks, get local config
        // sepolia -> get sepolia config
        config = helperConfig.getConfig();
    }

    function testIfCreateSubscriptionDeliversASubId() public {
        // Arrange / Act
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator, config.account);
        }
        // Assert
        assert(config.subscriptionId != 0);
    }

    function testIfFundSubscriptionIsWorking() public {
        // Arrange
        CreateSubscription createSubscription = new CreateSubscription();
        (config.subscriptionId, config.vrfCoordinator) =
            createSubscription.createSubscription(config.vrfCoordinator, config.account);

        address vrfCoordinator = helperConfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = config.subscriptionId;
        address linkToken = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;

        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinator: ", vrfCoordinator);
        console.log("On chain Id: ", block.chainid);

        // Act / Assert
        /**
         * @dev I couldn't check directly if the subscription is funded in each type of contract,
         * I'm checking the end state of each function that funds the subscription.
         * The Anvil function emits an event at the end, so I use vm.expectEmit.
         * The Sepolia function returns a "success" bool, so I check if it's true.
         */
        if (block.chainid == LOCAL_CHAIN_ID) {
            vm.startBroadcast(account);
            vm.expectEmit();
            emit SubscriptionFunded(config.subscriptionId, oldBalance, 3e20);
            VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT * 100);
            vm.stopBroadcast();
        } else {
            vm.startBroadcast(account);
            bool success = LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
            assert(success == true);
        }
    }

    function testIfAddConsumerIsWorking() public {
        // Arrange
        if (config.subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            (config.subscriptionId, config.vrfCoordinator) =
                createSubscription.createSubscription(config.vrfCoordinator, config.account);

            FundSubscription fundSubscription = new FundSubscription();
            fundSubscription.fundSubscription(config.vrfCoordinator, config.subscriptionId, config.link, config.account);
        }

        vm.startBroadcast(config.account);
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit
        );
        vm.stopBroadcast();

        // Act / Assert

        AddConsumer addConsumer = new AddConsumer();

        vm.expectEmit();
        emit SubscriptionConsumerAdded(config.subscriptionId, address(raffle));

        addConsumer.addConsumer(address(raffle), config.vrfCoordinator, config.subscriptionId, config.account);
    }
}
