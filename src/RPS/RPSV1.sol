// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IRPS.sol";
import "../YokiHelper.sol";

contract RPSV1 is IRPS, Initializable {
    bool public isTerminated = false;
    address public constant TREASURY = 0x400d0dbd2240c8cF16Ee74E628a6582a42bb4f35;
    uint256 public constant MIN_FREQUENCY = 60;

    string public merchantName;
    // processingFee = 30 is 3%
    uint8 public processingFee = 30; // commission in tenths of percent paid by service provider
    address public settlementAddress; // service provider address to receive subscriber payment
    address public tokenAddress; // ERC20 token used to pay for subscription
    uint256 public subscriptionCost; // amount of "token"s to withdraw from subscriber
    uint256 public frequency = MIN_FREQUENCY; // how ofter to substract subscription payment in unix timestamp

    mapping(address => uint256) private lastExecutionTimestamp;

    function initialize(
        string memory merchantName_,
        address settlementAddress_,
        address tokenAddress_,
        uint256 subscriptionCost_,
        uint256 frequency_,
        uint8 processingFee_
    ) public initializer {
        require(settlementAddress_ != address(0), "RPS: Invalid settlement address");
        require(tokenAddress_ != address(0), "RPS: Invalid token address");
        require(YokiHelper.isERC20(tokenAddress_), "RPS: Provided token address is not ERC20");
        require(subscriptionCost_ >= 1, "RPS: Subscription cost should be at least 1");
        require(frequency_ >= MIN_FREQUENCY, "RPS: Frequency should be at least 1 minute");
        require(processingFee_ >= 0 && processingFee_ <= 100, "RPS: Processing fee must be less than 100 (10%)");

        merchantName = merchantName_;
        settlementAddress = settlementAddress_;
        tokenAddress = tokenAddress_;
        subscriptionCost = subscriptionCost_;
        frequency = frequency_;
        processingFee = processingFee_;
    }

    function checkAllowanceAndBalance(address subscriber) internal view {
        IERC20 token = IERC20(tokenAddress);
        require(token.allowance(subscriber, address(this)) >= subscriptionCost, "RPS: Allowance is too low");
        require(token.balanceOf(subscriber) >= subscriptionCost, "RPS: User balance is too low");
    }

    function subscribe() public {
        require(!isTerminated, "RPS: Contract was terminated");
        require(!isSubscriber(msg.sender), "RPS: Already subscribed");
        checkAllowanceAndBalance(msg.sender);
        uint256 currentTimestamp = block.timestamp;
        lastExecutionTimestamp[msg.sender] = currentTimestamp - frequency;
        emit Subscribed(
            address(this), merchantName, address(msg.sender), lastExecutionTimestamp[msg.sender], currentTimestamp
        );
    }

    function canExecute(address subscriber) public view returns (bool) {
        require(!isTerminated, "RPS: Contract was terminated");
        require(isSubscriber(subscriber), "RPS: Not a subscriber");
        uint256 lastSubscriberExecutionTimestamp = lastExecutionTimestamp[subscriber];
        require(block.timestamp + 24 > lastSubscriberExecutionTimestamp + frequency, "RPS: Too soon to execute");
        checkAllowanceAndBalance(subscriber);
        return true;
    }

    function execute(address subscriber) public returns (uint256 nextExectuionTimestamp) {
        require(canExecute(subscriber), "RPS: Can't execute");
        uint256 subscriberLastExecutionTimestamp = getSubscriberLastExecutionTimestamp(subscriber);

        uint256 feeAmount = (subscriptionCost * processingFee) / 1000;
        uint256 amountToTransfer = subscriptionCost - feeAmount;
        YokiHelper.safeTransferFrom(address(tokenAddress), subscriber, TREASURY, feeAmount);
        YokiHelper.safeTransferFrom(address(tokenAddress), subscriber, settlementAddress, amountToTransfer);

        uint256 currentExecutionTimestamp = subscriberLastExecutionTimestamp + frequency;
        uint256 nextExecutionTimestamp = currentExecutionTimestamp + frequency;
        // if execute was not called in proper time-period (ex. previouse frequency was skipped) - reset timer
        if (currentExecutionTimestamp + frequency < block.timestamp) {
            lastExecutionTimestamp[subscriber] = block.timestamp;
            nextExecutionTimestamp = block.timestamp + frequency;
        } else {
            // otherwise - treat current execution as it was executed exactly after frequency passed
            lastExecutionTimestamp[subscriber] = currentExecutionTimestamp;
        }

        emit Executed(
            address(this),
            address(msg.sender),
            subscriber,
            merchantName,
            settlementAddress,
            amountToTransfer,
            feeAmount,
            nextExecutionTimestamp
        );

        return nextExecutionTimestamp;
    }

    function isSubscriber(address subscriber) public view returns (bool) {
        return (lastExecutionTimestamp[subscriber] != 0);
    }

    function getSubscriberLastExecutionTimestamp(address subscriber)
        public
        view
        returns (uint256 subscriberLastExecutionTimestamp)
    {
        require(isSubscriber(subscriber), "RPS: Not a subscriber");
        return lastExecutionTimestamp[subscriber];
    }

    function unsubscribe() public {
        unsubscribe(msg.sender);
    }

    function unsubscribe(address subscriber) public {
        require(isSubscriber(subscriber), "RPS: Subscriber not found");
        require(msg.sender == settlementAddress || msg.sender == subscriber, "RPS: Forbidden");
        delete lastExecutionTimestamp[subscriber];
        emit Unsubscribed(address(this), subscriber);
    }

    function terminate() public {
        require(msg.sender == settlementAddress, "RPS: Forbidden");
        isTerminated = true;
        emit Terminated(address(this));
    }
}
