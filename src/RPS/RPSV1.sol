// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// TODO: use open-zepplin helper instead
import "@uniswap-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RPSV1 is Initializable {
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

    event executed(
        address contractAddress,
        address executor,
        string marchantName,
        address target,
        uint256 subscriptionCost,
        uint256 fee,
        uint256 nextExecutionTimestamp
    );
    event unsubscribed(address contractAddress, address subscriber);
    event terminated(address contractAddress);

    // TODO: move to helpers
    function _checkIsERC20(address token) internal view returns (bool) {
        try IERC20(token).totalSupply() returns (uint256) {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }

    function initialize(
        string memory merchantName_,
        address target_,
        address tokenAddress_,
        uint256 subscriptionCost_,
        uint256 frequency_,
        uint8 fee_
    ) public initializer {
        require(target != address(0), "RPS: Invalid target address");
        require(tokenAddress != address(0), "RPS: Invalid token address");
        require(_checkIsERC20(tokenAddress), "RPS: Provided token address is not ERC20");
        require(subscriptionCost_ > 100, "RPS: Subscription cost should be at least 100");
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
        require(isSubscriber(msg.sender), "RPS: Already subscribed");
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
        uint256 lastSubscriberExecutionTimestamp = lastExecutionTimestamp[subscriber];

        uint256 feeAmount = (subscriptionCost * fee) / 100;
        uint256 amountToTransfer = subscriptionCost - fee;
        TransferHelper.safeTransferFrom(address(tokenAddress), subscriber, TREASURY, feeAmount);
        TransferHelper.safeTransferFrom(address(tokenAddress), subscriber, target, amountToTransfer);

        uint256 nextExecutionTimestamp = lastSubscriberExecutionTimestamp + frequency;
        // if execute was not called in proper time-period (ex. previouse frequency was skipped) - reset timer
        if (nextExecutionTimestamp + frequency < block.timestamp) {
            lastExecutionTimestamp[subscriber] = block.timestamp;
        } else {
            // otherwise - treat last execution as it was executed exactly after frequency stated amount of time
            lastExecutionTimestamp[subscriber] = lastSubscriberExecutionTimestamp + frequency;
        }
        emit executed(
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

    function unsubscribe(address subscriber) public {
        require(isSubscriber(subscriber), "RPS: Subscriber not found");
        require(msg.sender == target || msg.sender == subscriber, "RPS: Forbidden");
        delete lastExecutionTimestamp[subscriber];
        emit terminated(subscriber);
    }

    function terminate() public {
        require(msg.sender == target, "RPS: Forbidden");
        isTerminated = true;
    }
}