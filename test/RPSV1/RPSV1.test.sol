pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@RPS/RPSV1.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../helpers/AssetsHelper.sol";

contract RPSV1Test is Test {
    event Executed(
        address contractAddress,
        address executor,
        address subscriber,
        string merchantName,
        address settlementAddress,
        uint256 transfered,
        uint256 fee,
        uint256 nextExecutionTimestamp
    );
    event Subscribed(
        address contractAddress,
        address subscriber,
        address settlementAddress,
        string merchantName,
        uint256 transfered,
        uint256 fee,
        uint256 lastExecutionTimestamp,
        uint256 nextExecutionTimestamp
    );
    event Unsubscribed(address contractAddress, address subscriber);
    event Terminated(address contractAddress);

    RPSV1 rps;
    address merchantAddress;
    address assetAddress;
    uint256 subscriptionCost = 100;
    uint256 frequency = 36000;
    string public merchantName = "Merchant";
    uint8 fee = 30; // 3%

    address subscriber;
    uint256 subscriberBalance = 1000;
    AssetsHelper assetsHelper;

    address owner;
    // Sunday, 9 September 2001 01:46:40
    uint256 subscribedAt = 1000000000;

    function setUp() public {
        vm.warp(subscribedAt);
        owner = makeAddr("owner");
        merchantAddress = makeAddr("merchant");
        assetsHelper = new AssetsHelper(1);
        assetAddress = assetsHelper.getAssetsAddresses()[0];
        ERC20 asset = ERC20(assetAddress);

        subscriber = makeAddr("subscriber");
        assetsHelper.dealTokens(assetsHelper.assets(0), subscriber, subscriberBalance);

        rps = new RPSV1();

        vm.prank(subscriber);
        asset.approve(address(rps), subscriberBalance);

        vm.prank(owner);
        rps.initialize(merchantName, merchantAddress, assetAddress, subscriptionCost, frequency, fee);

        vm.prank(subscriber);
        rps.subscribe();

        // ______ rps.subscribe took all funds and approvals back to zero ______

        // __reset subscriber__
        // we want to make our subscriber default again
        vm.prank(subscriber);
        asset.approve(address(rps), subscriberBalance);
        // deal tokens to match wallet balance to subscriberBalance variable
        vm.prank(owner);
        assetsHelper.dealTokens(assetsHelper.assets(0), subscriber, subscriberBalance - asset.balanceOf(subscriber));

        // __reset treasury and owner__
        address treasury = rps.TREASURY();

        vm.prank(treasury);
        asset.transfer(address(makeAddr("trash_can")), 3);
        vm.prank(merchantAddress);
        asset.transfer(address(makeAddr("trash_can")), 97);

        // TODO: some forge shenanigans prevents this one from working (despite balanceOf returning correctly 3)
        // asset.transfer(address(makeAddr("trash_can")), asset.balanceOf(treasury))
    }

    function test_RPSV1_subscribe() public {
        ERC20 asset = ERC20(assetAddress);
        address newSubscriber = makeAddr("newSubscriber");
        address treasury = rps.TREASURY();
        uint256 expectedTransfered = subscriptionCost * (1000 - fee) / 1000;
        uint256 expectedFee = subscriptionCost * fee / 1000;

        vm.startPrank(newSubscriber);

        asset.approve(address(rps), subscriptionCost);
        assetsHelper.dealTokens(asset, newSubscriber, subscriptionCost);

        vm.expectEmit(address(rps));
        emit Subscribed(
            address(rps),
            address(newSubscriber),
            rps.settlementAddress(),
            merchantName,
            expectedTransfered,
            expectedFee,
            subscribedAt,
            subscribedAt + frequency
        );
        rps.subscribe();

        // validate subscription success
        assertTrue(rps.isSubscriber(newSubscriber));
        assertEq(rps.getSubscriberLastExecutionTimestamp(newSubscriber), subscribedAt);

        // validate execution success
        assertEq(asset.balanceOf(treasury), expectedFee);
        assertEq(asset.balanceOf(merchantAddress), expectedTransfered);
        assertEq(asset.balanceOf(merchantAddress) + asset.balanceOf(treasury), subscriptionCost);
        assertEq(asset.balanceOf(newSubscriber), 0);
    }

    function test_RPSV1_subscribe_validations() public {
        ERC20 asset = ERC20(assetAddress);
        address newSubscriber = makeAddr("newSubscriber");
        vm.startPrank(newSubscriber);
        vm.expectRevert("RPS: Allowance is too low");
        rps.subscribe();
        asset.approve(address(rps), subscriptionCost);

        vm.expectRevert("RPS: User balance is too low");
        rps.subscribe();
        assetsHelper.dealTokens(asset, newSubscriber, subscriptionCost);

        rps.subscribe();
        assertTrue(rps.isSubscriber(newSubscriber));
        assertEq(rps.getSubscriberLastExecutionTimestamp(newSubscriber), subscribedAt);
    }

    function test_RPSV1_canExecute() public {
        // fresh subscription
        vm.prank(makeAddr("random_user"));

        vm.expectRevert("RPS: Too soon to execute");
        rps.canExecute(subscriber);

        vm.warp(subscribedAt + frequency);
        assertTrue(rps.canExecute(subscriber));
    }

    function test_RPSV1_canExecute_validations() public {
        ERC20 asset = ERC20(assetAddress);
        address newSubscriber = makeAddr("newSubscriber");
        vm.startPrank(newSubscriber);
        vm.expectRevert("RPS: Not a subscriber");
        rps.canExecute(newSubscriber);

        // Provide assets to allow subscription
        asset.approve(address(rps), subscriptionCost);
        assetsHelper.dealTokens(asset, newSubscriber, subscriptionCost);
        rps.subscribe();
        // take away assets to test balances validations
        asset.approve(address(rps), 0);
        asset.transfer(address(makeAddr("trash_can")), asset.balanceOf(newSubscriber));

        vm.expectRevert("RPS: Too soon to execute");
        rps.canExecute(newSubscriber);
        vm.warp(subscribedAt + frequency);

        vm.expectRevert("RPS: Allowance is too low");
        rps.canExecute(newSubscriber);
        asset.approve(address(rps), subscriptionCost);

        vm.expectRevert("RPS: User balance is too low");
        rps.canExecute(newSubscriber);
        assetsHelper.dealTokens(asset, newSubscriber, subscriptionCost);

        assertTrue(rps.canExecute(newSubscriber));
    }

    function test_RPSV1_unsubscribe() public {
        vm.startPrank(subscriber);
        vm.expectEmit(address(rps));
        emit Unsubscribed(address(rps), subscriber);
        rps.unsubscribe(subscriber);

        vm.expectRevert("RPS: Not a subscriber");
        rps.getSubscriberLastExecutionTimestamp(subscriber);
        assertFalse(rps.isSubscriber(subscriber));
    }

    function test_RPSV1_unsubscribe_by_merchant() public {
        vm.startPrank(merchantAddress);
        vm.expectEmit(address(rps));
        emit Unsubscribed(address(rps), subscriber);
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
        ERC20 asset = ERC20(assetAddress);
        assertEq(asset.balanceOf(treasury), 0);
        assertEq(asset.balanceOf(merchantAddress), 0);

        // warp to next execution timestamp
        vm.warp(subscribedAt + frequency);

        // fee = 30 (3%) | expectedTransfered = 97% of 100 -> 97
        uint256 expectedTransfered = subscriptionCost * (1000 - fee) / 1000;
        // expectedFee = 3% of 100 -> 3
        uint256 expectedFee = subscriptionCost * fee / 1000;
        // when subscribed + when allowed to be executed + delay after execution
        uint256 expectedNextExecutionTimestamp = subscribedAt + frequency + frequency;

        vm.prank(owner);
        vm.expectEmit(address(rps));
        emit Executed(
            address(rps),
            owner,
            subscriber,
            merchantName,
            merchantAddress,
            expectedTransfered,
            expectedFee,
            expectedNextExecutionTimestamp
        );
        assertEq(rps.execute(subscriber), expectedNextExecutionTimestamp);

        assertEq(asset.balanceOf(treasury), expectedFee);
        assertEq(asset.balanceOf(merchantAddress), expectedTransfered);
        assertEq(asset.balanceOf(merchantAddress) + asset.balanceOf(treasury), subscriptionCost);
        assertEq(asset.balanceOf(subscriber), subscriberBalance - subscriptionCost);
    }

    function test_RPSV1_execute_after_first_one_was_missed() public {
        uint256 futureTimestamp = frequency * 2 + subscribedAt + 100; // simulate that we skipped one payment
        vm.warp(futureTimestamp);
        assertEq(rps.execute(subscriber), futureTimestamp + frequency);
        assertEq(rps.getSubscriberLastExecutionTimestamp(subscriber), futureTimestamp);
    }

    function test_RPSV1_terminate() public {
        vm.prank(merchantAddress);
        vm.expectEmit(address(rps));
        emit Terminated(address(rps));
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
