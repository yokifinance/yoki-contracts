pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@RPS/RPSV1.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../helpers/AssetsHelper.sol";

contract RPSV1Test is Test {
    event executed(
        address contractAddress,
        address executor,
        string merchantName,
        address target,
        uint256 transfered,
        uint256 fee,
        uint256 nextExecutionTimestamp
    );
    event unsubscribed(address contractAddress, address subscriber);
    event terminated(address contractAddress);

    RPSV1 rps;
    address merchantAddress;
    address assetAddress;
    uint256 subscriptionCost = 100;
    uint256 frequency = 36000;
    string public merchantName = "Merchant";
    uint8 fee = 3;

    address subscriber;
    uint256 subscriberBalance = 1000;
    AssetsHelper assetsHelper;

    address public owner;
    // Sunday, 9 September 2001 01:46:40
    uint256 mockTimestamp = 1000000000;

    function setUp() public {
        vm.warp(mockTimestamp);
        owner = makeAddr("owner");
        merchantAddress = makeAddr("merchant");
        assetsHelper = new AssetsHelper(1);
        assetAddress = assetsHelper.getAssetsAddresses()[0];

        subscriber = makeAddr("subscriber");
        assetsHelper.dealTokens(assetsHelper.assets(0), subscriber, subscriberBalance);

        rps = new RPSV1();

        vm.prank(subscriber);
        ERC20(assetAddress).approve(address(rps), subscriberBalance);

        vm.prank(owner);
        rps.initialize(merchantName, merchantAddress, assetAddress, subscriptionCost, frequency, fee);

        vm.prank(subscriber);
        rps.subscribe();
    }

    function test_RPSV1_subscribe() public {
        address newSubscriber = makeAddr("newSubscriber");
        vm.startPrank(newSubscriber);
        rps.subscribe();
        assertTrue(rps.isSubscriber(newSubscriber));
        assertEq(rps.getSubscriberLastExecutionTimestamp(newSubscriber), mockTimestamp - frequency);
    }

    function test_RPSV1_canExecute() public {
        vm.prank(makeAddr("random_user"));
        assertTrue(rps.canExecute(subscriber));
    }

    function test_RPSV1_canExecute_validations() public {
        ERC20 asset = ERC20(assetAddress);
        address newSubscriber = makeAddr("newSubscriber");
        vm.startPrank(newSubscriber);
        vm.expectRevert("RPS: Not a subscriber");
        rps.canExecute(newSubscriber);
        rps.subscribe();

        vm.warp(mockTimestamp - frequency - 25);
        vm.expectRevert("RPS: Too soon to execute");
        rps.canExecute(newSubscriber);
        vm.warp(mockTimestamp);

        vm.expectRevert("RPS: Allowance is too low");
        rps.canExecute(newSubscriber);
        asset.approve(address(rps), subscriberBalance);

        vm.expectRevert("RPS: User balance is too low");
        rps.canExecute(newSubscriber);
        assetsHelper.dealTokens(asset, newSubscriber, subscriberBalance);

        assertTrue(rps.canExecute(newSubscriber));
    }

    function test_RPSV1_unsubscribe() public {
        vm.startPrank(subscriber);
        vm.expectEmit(address(rps));
        emit unsubscribed(address(rps), subscriber);
        rps.unsubscribe(subscriber);

        vm.expectRevert("RPS: Not a subscriber");
        rps.getSubscriberLastExecutionTimestamp(subscriber);
        assertFalse(rps.isSubscriber(subscriber));
    }

    function test_RPSV1_unsubscribe_by_merchant() public {
        vm.startPrank(merchantAddress);
        vm.expectEmit(address(rps));
        emit unsubscribed(address(rps), subscriber);
        rps.unsubscribe(subscriber);

        vm.expectRevert("RPS: Not a subscriber");
        rps.getSubscriberLastExecutionTimestamp(subscriber);
        assertFalse(rps.isSubscriber(subscriber));
    }

    function test_RPSV1_unsubscribe_validation() public {
        address randomUser = makeAddr("random_user");
        vm.expectRevert("RPS: Subscriber not found");
        rps.unsubscribe(randomUser);

        vm.prank(randomUser);
        vm.expectRevert("RPS: Forbidden");
        rps.unsubscribe(subscriber);
    }

    function test_RPSV1_execute() public {
        address treasury = rps.TREASURY();
        ERC20 token = ERC20(assetAddress);
        assertEq(token.balanceOf(treasury), 0);
        assertEq(token.balanceOf(merchantAddress), 0);

        uint256 expectedTransfered = subscriptionCost * (100 - fee) / 100;
        uint256 expectedFee = subscriptionCost * fee / 100;

        vm.prank(owner);
        vm.expectEmit(address(rps));
        emit executed(
            address(rps),
            owner,
            merchantName,
            merchantAddress,
            expectedTransfered,
            expectedFee,
            mockTimestamp + frequency
        );
        assertEq(rps.execute(subscriber), mockTimestamp + frequency);

        assertEq(token.balanceOf(treasury), expectedFee);
        assertEq(token.balanceOf(merchantAddress), expectedTransfered);
    }

    function test_RPSV1_execute_after_first_one_was_missed() public {
        uint256 futureTimestamp = frequency * 2 + mockTimestamp + 100; // simulate that we skipped one payment
        vm.warp(futureTimestamp);
        assertEq(rps.execute(subscriber), futureTimestamp + frequency);
        assertEq(rps.getSubscriberLastExecutionTimestamp(subscriber), futureTimestamp);
    }

    function test_RPSV1_terminate() public {
        vm.prank(merchantAddress);
        vm.expectEmit(address(rps));
        emit terminated(address(rps));
        rps.terminate();

        vm.expectRevert("RPS: Contract was terminated");
        rps.subscribe();

        vm.expectRevert("RPS: Contract was terminated");
        rps.canExecute(subscriber);

        vm.expectRevert("RPS: Contract was terminated");
        rps.execute(subscriber);
    }

    function test_RPSV1_terminate_validation() public {
        vm.prank(owner);
        vm.expectRevert("RPS: Forbidden");
        rps.terminate();
    }
}
