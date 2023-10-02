// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "./DcaCore.sol";
import {MetaAggregationRouterV2} from "@kyberswap/MetaAggregationRouterV2.sol";

contract DCAV3 is DCACore {
    function executeKyberswap(uint256 positionIndex, MetaAggregationRouterV2.SwapExecutionParams memory params)
        external
    {
        Position storage pos = _allPositions[positionIndex];
        address tokenIn = pos.tokenToSpend;
        address tokenOut = pos.tokenToBuy;
        address recipient = params.desc.dstReceiver;
        uint256 amountIn = params.desc.amount;

        // require(pos.executor == msg.sender, "DCA: Wrong executor");
        require(block.timestamp - pos.lastPurchaseTimestamp > EXECUTION_COOLDOWN, "DCA: Too early for a next purchase");
        require(pos.beneficiary == recipient, "DCA: Wrong recipient");
        require(pos.singleSpendAmount == amountIn, "DCA: Wrong amount");
        require(tokenIn == address(params.desc.srcToken), "DCA: Wrong input token");
        require(tokenOut == address(params.desc.dstToken), "DCA: Wrong output token");
        require(IERC20(tokenIn).balanceOf(recipient) >= amountIn, "DCA: Not enough funds");

        // Transfer tokens from user to this contract
        TransferHelper.safeTransferFrom(tokenIn, recipient, address(this), amountIn);

        // TODO: we can't modify kyberswap request, we need another way to handle fees !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        // uint256 amountAfterHandleFee = _handleFees(tokenIn, amountIn);
        // _params.amountIn = amountAfterHandleFee;

        // Execute swap and result send to user (_params.recipient)
        (uint256 amountOut, uint256 gasUsed) = MetaAggregationRouterV2(payable(address(swapRouter))).swap(params);
        pos.lastPurchaseTimestamp = block.timestamp;

        emit PurchaseExecuted(positionIndex, tokenIn, tokenOut, amountIn, amountOut);
    }
}
