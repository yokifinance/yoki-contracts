// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRPS {
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

    function isSubscriber(address subscriber) external view returns (bool);
    function subscribe() external;
    function unsubscribe() external;
    function canExecute(address subscriber) external view returns (bool);
    function execute(address subscriber) external returns (uint256 nextExectuionTimestamp);
    function terminate() external;
}
