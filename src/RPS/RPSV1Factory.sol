// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@uniswap-periphery/contracts/libraries/TransferHelper.sol";

struct SubscriptionDetails {
    address token;
    uint256 amount;
    uint256 frequency;
}

contract RPSV1Factory {
    address public rpsImpl;

    event SubscriptionCreated(
        address indexed contractAddress, address indexed userWalletAddress, SubscriptionDetails subDetails
    );

    constructor(address rpsImp_) {
        require(rpsImp_ != address(0));
        rpsImpl = rpsImp_;
    }

    function createRPS(address token, uint256 amount, uint256 frequency) external returns (address newDcaProxy) {
        address from = msg.sender;
        address newRpsProxy = _deployRPS(from, token, amount, frequency);
        TransferHelper.safeApprove(token, newRpsProxy, type(uint256).max);

        emit SubscriptionCreated(
            address(newRpsProxy), from, SubscriptionDetails({token: token, amount: amount, frequency: frequency})
        );

        return newRpsProxy;
    }

    function _deployRPS(address newOwner, address token, uint256 amount, uint256 frequency)
        internal
        returns (address)
    {
        address proxy = Clones.clone(rpsImpl);

        RPSV1(proxy).initialize(newOwner, token, amount, frequency);

        return proxy;
    }
}
