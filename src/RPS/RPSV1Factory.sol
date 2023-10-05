// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@uniswap-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./RPSV1.sol";

contract RPSV1Factory is AccessControl {
    address public rpsImpl;

    event SubscriptionCreated(address indexed contractAddress, string merchantName);

    constructor(address rpsImp_, address[] memory admins) {
        require(rpsImp_ != address(0));
        rpsImpl = rpsImp_;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender); // Super admin - can grant and revoke roles
        for (uint256 i = 0; i < admins.length; i++) {
            _setupRole("ADMIN", admins[i]);
        }
    }

    function createRPS(
        string calldata merchantName,
        address merchantAddress,
        address tokenAddress,
        uint256 subscriptionCost,
        uint256 frequency,
        uint8 fee
    ) external returns (address newDcaProxy) {
        require(hasRole("ADMIN", _msgSender()), "RPS: Forbidden");
        address proxy = Clones.clone(rpsImpl);

        RPSV1(proxy).initialize(merchantName, merchantAddress, tokenAddress, subscriptionCost, frequency, fee);

        TransferHelper.safeApprove(tokenAddress, proxy, type(uint256).max);

        emit SubscriptionCreated(address(proxy), merchantName);

        return proxy;
    }
}
