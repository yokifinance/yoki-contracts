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
    uint8 public fee = 3; // commission %
    address public target; // merchant address
    address public tokenAddress; // ERC20 token used to pay for subscription
    uint256 public subscriptionCost; // amount of "token"s to withdraw from subscriber
    uint256 public frequency = MIN_FREQUENCY; // how ofter to substract subscription payment in unix timestamp

    mapping(address => uint256) private lastExecutionTimestamp;

    function initialize(
        string memory merchantName_,
        address target_,
        address tokenAddress_,
        uint256 subscriptionCost_,
        uint256 frequency_,
        uint8 fee_
    ) public initializer {
        require(target_ != address(0), "RPS: Invalid target address");
        require(tokenAddress_ != address(0), "RPS: Invalid token address");
        require(YokiHelper.isERC20(tokenAddress_), "RPS: Provided token address is not ERC20");
        require(subscriptionCost_ >= 1, "RPS: Subscription cost should be at least 1");
        require(frequency_ > MIN_FREQUENCY, "RPS: Frequency should be at least 1 minute");
        require(fee_ >= 0 && fee_ <= 10, "RPS: Fee must be more than 0 and less than 10");

        merchantName = merchantName_;
        target = target_;
        tokenAddress = tokenAddress_;
        subscriptionCost = subscriptionCost_;
        frequency = frequency_;
        fee = fee_;
    }

    function subscribe() public {
        require(!isTerminated, "RPS: Contract was terminated");
        require(!isSubscriber(msg.sender), "RPS: Already subscribed");
        lastExecutionTimestamp[msg.sender] = block.timestamp - frequency;
    }

    function canExecute(address subscriber) public view returns (bool) {
        require(!isTerminated, "RPS: Contract was terminated");
        require(isSubscriber(subscriber), "RPS: Not a subscriber");
        uint256 lastSubscriberExecutionTimestamp = lastExecutionTimestamp[subscriber];
        require(block.timestamp + 24 > lastSubscriberExecutionTimestamp + frequency, "RPS: Too soon to execute");
        IERC20 token = IERC20(tokenAddress);
        require(token.allowance(subscriber, address(this)) > subscriptionCost, "RPS: Allowance is too low");
        require(token.balanceOf(subscriber) > subscriptionCost, "RPS: User balance is too low");
        return true;
    }

    function execute(address subscriber) public returns (uint256 nextExectuionTimestamp) {
        require(canExecute(subscriber), "RPS: Can't execute");
        uint256 subscriberLastExecutionTimestamp = getSubscriberLastExecutionTimestamp(subscriber);

        uint256 feeAmount = (subscriptionCost * fee) / 100;
        uint256 amountToTransfer = subscriptionCost - fee;
        YokiHelper.safeTransferFrom(address(tokenAddress), subscriber, TREASURY, feeAmount);
        YokiHelper.safeTransferFrom(address(tokenAddress), subscriber, target, amountToTransfer);

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
            merchantName,
            target,
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
        require(msg.sender == target || msg.sender == subscriber, "RPS: Forbidden");
        delete lastExecutionTimestamp[subscriber];
        emit Unsubscribed(address(this), subscriber);
    }

    function terminate() public {
        require(msg.sender == target, "RPS: Forbidden");
        isTerminated = true;
        emit Terminated(address(this));
    }
}
