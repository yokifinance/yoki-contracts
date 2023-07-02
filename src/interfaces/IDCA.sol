// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/IAssetsWhitelist.sol";
import "@uniswap/contracts/interfaces/ISwapRouter.sol";

interface IDCA {
    /**
     * @dev Contains all information for a specific position.
     */
    struct Position {
        address beneficiary;
        address executor;
        uint256 singleSpendAmount;
        address tokenToSpend;
        address tokenToBuy;
        uint256 lastPurchaseTimestamp;
    }

    event BeneficiaryChanged(
        uint256 positionIndex,
        address newBeneficiary
    );

    event SingleSpendAmountChanged(
        uint256 positionIndex,
        uint256 newSingleSpendAmount
    );

    event PositionOpened(
        uint256 newPositionIndex,
        address beneficiary,
        address executor,
        uint256 singleSpendAmount,
        address tokenToSpend,
        address tokenToBuy
    );

    event PurchaseExecuted(
        uint256 positionIndex,
        address tokenSpent,
        address tokenAcquired,
        uint256 amountSpent,
        uint256 amountAcquired
    );

    event FundsRetrieved(address tokenRetrieved, uint256 amountRetrieved, address recipient);

    function initialize(
        IAssetsWhitelist assetsWhitelist_,
        address swapRouter_,
        address newOwner_,
        Position calldata initialPosition_
    ) external;

    function executeMultihopPurchase(
        uint256 positionIndex,
        ISwapRouter.ExactInputParams memory params
    ) external;

    function executeSinglePurchase(
        uint256 positionIndex,
        ISwapRouter.ExactInputSingleParams memory params
    ) external;

    function allPositionsLength() external view returns (uint256);

    function getPosition(uint256 positionIndex) external view returns (Position memory);

    function setBeneficiary(uint256 positionIndex, address newBeneficiary) external;

    function openPosition(Position calldata newPosition) external;
}
