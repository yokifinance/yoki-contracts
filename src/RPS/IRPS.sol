// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@uniswap-periphery/contracts/interfaces/ISwapRouter.sol";

interface IRPS {
    event Executed(
        address contractAddress,
        address executor,
        string merchantName,
        address target,
        uint256 transfered,
        uint256 fee,
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
