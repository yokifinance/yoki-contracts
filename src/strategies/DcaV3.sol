// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "./DcaCore.sol";
import "../libraries/Path.sol";
import "@uniswap-periphery/contracts/interfaces/ISwapRouter.sol";

contract DCAV3 is DCACore {
    using Path for bytes;

    function executeMultihopPurchase(
        uint256 positionIndex,
        ISwapRouter.ExactInputParams memory params
    ) external {
        Position storage pos = _allPositions[positionIndex];
        require(pos.executor == msg.sender, "DCA: Wrong executor");

        _multihopExactInputSwap(positionIndex, pos, params);
    }

    function executeSinglePurchase(
        uint256 positionIndex,
        ISwapRouter.ExactInputSingleParams memory params
    ) external {
        Position storage pos = _allPositions[positionIndex];
        require(pos.executor == msg.sender, "DCA: Wrong executor");

        _singleExactInputSwap(positionIndex, pos, params);
    }

    function _multihopExactInputSwap(
        uint256 _positionIndex,
        Position storage _pos,
        ISwapRouter.ExactInputParams memory _params
    ) internal {
        require(
            block.timestamp - _pos.lastPurchaseTimestamp > EXECUTION_COOLDOWN,
            "DCA: Too early for a next purchase"
        );

        require(_pos.beneficiary == _params.recipient, "DCA: Wrong recipient");
        require(
            _pos.singleSpendAmount == _params.amountIn,
            "DCA: Wrong amount"
        );

        bool hasMultiplePools = _params.path.hasMultiplePools();
        (address tokenIn, address tokenOut) = _params.path.decodeFirstPool();

        require(tokenIn == _pos.tokenToSpend, "DCA: Wrong input token");

        require(
            IERC20(tokenIn).balanceOf(_params.recipient) >= _params.amountIn,
            "DCA: Not enough funds"
        );

        // Transfer tokens from user to this contract
        TransferHelper.safeTransferFrom(
            tokenIn,
            _params.recipient,
            address(this),
            _params.amountIn
        );

        uint256 amountAfterHandleFee = _handleFees(tokenIn, _params.amountIn);
        _params.amountIn = amountAfterHandleFee;

        bytes memory tempPath;

        if (hasMultiplePools) {
            tempPath = _params.path.skipToken();
            while (true) {
                hasMultiplePools = tempPath.hasMultiplePools();
                (tokenIn, tokenOut) = tempPath.decodeFirstPool();

                if (hasMultiplePools) {
                    tempPath = tempPath.skipToken();
                } else {
                    break;
                }
            }
        }

        require(tokenOut == _pos.tokenToBuy, "DCA: Wrong output token");

        // Execute swap and result send to user (_params.recipient)
        uint256 amountOut = ISwapRouter(swapRouter).exactInput(_params);
        _pos.lastPurchaseTimestamp = block.timestamp;

        emit PurchaseExecuted(
            _positionIndex,
            _pos.tokenToSpend,
            _pos.tokenToBuy,
            _params.amountIn,
            amountOut
        );
    }

    function _singleExactInputSwap(
        uint256 _positionIndex,
        Position storage _pos,
        ISwapRouter.ExactInputSingleParams memory _params
    ) internal {
        require(
            block.timestamp - _pos.lastPurchaseTimestamp > EXECUTION_COOLDOWN,
            "DCA: Too early for a next purchase"
        );

        require(_pos.beneficiary == _params.recipient, "DCA: Wrong recipient");
        require(
            _pos.singleSpendAmount == _params.amountIn,
            "DCA: Wrong amount"
        );

        address tokenIn = _params.tokenIn;
        address tokenOut = _params.tokenOut;

        require(tokenIn == _pos.tokenToSpend, "DCA: Wrong input token");

        require(
            IERC20(tokenIn).balanceOf(_params.recipient) >= _params.amountIn,
            "DCA: Not enough funds"
        );

        // Transfer tokens from user to this contract
        TransferHelper.safeTransferFrom(
            tokenIn,
            _params.recipient,
            address(this),
            _params.amountIn
        );

        uint256 amountAfterHandleFee = _handleFees(tokenIn, _params.amountIn);
        _params.amountIn = amountAfterHandleFee;

        require(tokenOut == _pos.tokenToBuy, "DCA: Wrong output token");

        // Execute swap and result send to user (_params.recipient)
        uint256 amountOut = ISwapRouter(swapRouter).exactInputSingle(_params);
        _pos.lastPurchaseTimestamp = block.timestamp;

        emit PurchaseExecuted(
            _positionIndex,
            _pos.tokenToSpend,
            _pos.tokenToBuy,
            _params.amountIn,
            amountOut
        );
    }
}
