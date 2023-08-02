// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "interfaces/IDCA.sol";
import "interfaces/IAssetsWhitelist.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "@openzeppelin-upgradeable/contracts/security/ReentrancyGuardUpgradeable.sol";
import "@uniswap-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";


abstract contract DCACore is Initializable, IDCA, OwnableUpgradeable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {
    Position[] internal _allPositions;
    IAssetsWhitelist public assetsWhitelist;
    address public swapRouter;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    address public constant TREASURY = 0x400d0dbd2240c8cF16Ee74E628a6582a42bb4f35;
    uint256 public constant EXECUTION_COOLDOWN = 3300;

    uint256 public constant BASIS_POINTS = 1000;
    uint256 public constant MAX_FEE_MULTIPLIER = 50; // Represents 5%
    uint256 public commissionFee = 0;

    function initialize(
        IAssetsWhitelist assetsWhitelist_,
        address swapRouter_,
        address newOwner_,
        Position calldata initialPosition_
    ) public override initializer {
        require(address(assetsWhitelist_) != address(0), "DCA: whitelist is the zero address");
        require(swapRouter_ != address(0), "DCA: swapRouter is the zero address");

        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        assetsWhitelist = assetsWhitelist_;
        swapRouter = swapRouter_;
        transferOwnership(newOwner_);
        _openPosition(initialPosition_);
        _setupRole(ADMIN_ROLE, TREASURY);
    }

    function allPositionsLength() external view returns (uint256) {
        return _allPositions.length;
    }

    function getPosition(uint256 positionIndex) external view returns (Position memory) {
        return _allPositions[positionIndex];
    }

    function retrieveFunds(address[] memory assets, address recipient) external onlyOwner {
        require(recipient != address(0), "DCA: recipient is the zero address");

        uint256 len = assets.length;
        uint256 balance;

        for (uint256 i = 0; i < len; i++) {
            balance = IERC20(assets[i]).balanceOf(address(this));
            TransferHelper.safeTransfer(assets[i], recipient, balance);

            emit FundsRetrieved(assets[i], balance, recipient);
        }
    }

    function setBeneficiary(uint256 positionIndex, address newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "DCA: new beneficiary is the zero address");
        Position storage pos = _allPositions[positionIndex];
        pos.beneficiary = newBeneficiary;

        emit BeneficiaryChanged(positionIndex, newBeneficiary);
    }

    function setSingleSpendAmount(uint256 positionIndex, uint256 newSingleSpendAmount) external onlyOwner {
        require(newSingleSpendAmount > 0, "DCA: new spend amount is too small");
        Position storage pos = _allPositions[positionIndex];
        pos.singleSpendAmount = newSingleSpendAmount;

        emit SingleSpendAmountChanged(positionIndex, newSingleSpendAmount);
    }

    function setCommissionFee(uint256 newCommissionFee) external returns (uint256) {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Must have admin role to set commission fee");
        require(newCommissionFee <= MAX_FEE_MULTIPLIER, "Commission fee can't be higher than MAX_FEE_MULTIPLIER");

        commissionFee = newCommissionFee;

        emit CommissionFeeChanged(commissionFee, msg.sender);
        return commissionFee;
    }

    function _handleFees(
        address _token,
        uint256 _amount
    ) internal returns (uint256) {
        require(commissionFee <= MAX_FEE_MULTIPLIER, 'DCA: fee is too high');

        if(commissionFee == 0) {
            // If feeMultiplier is 0, exit function without making a transfer
            return _amount;
        }

        uint256 fee = _amount * commissionFee / BASIS_POINTS;

        TransferHelper.safeTransfer(
            _token,
            TREASURY,
            fee
        );
        uint256 newAmount = _amount - fee;
        return newAmount;
    }

    function openPosition(Position calldata _newPosition) external onlyOwner {
        _openPosition(_newPosition);
    }

    function _openPosition(Position memory _newPosition) internal {
        require(_newPosition.beneficiary != address(0), "DCA: beneficiary is the zero address");
        require(_newPosition.executor != address(0), "DCA: executor is the zero address");
        require(_newPosition.singleSpendAmount > 0, "DCA: spend amount is too small");

        require(
            assetsWhitelist.checkIfWhitelisted(_newPosition.tokenToSpend, _newPosition.tokenToBuy),
            "DCA: not whitelisted tokens are used"
        );

        TransferHelper.safeApprove(_newPosition.tokenToSpend, swapRouter, type(uint256).max);

        Position memory pos = Position(
            _newPosition.beneficiary,
            _newPosition.executor,
            _newPosition.singleSpendAmount,
            _newPosition.tokenToSpend,
            _newPosition.tokenToBuy,
            0
        );

        _allPositions.push(pos);

        emit PositionOpened(
            _allPositions.length - 1,
            _newPosition.beneficiary,
            _newPosition.executor,
            _newPosition.singleSpendAmount,
            _newPosition.tokenToSpend,
            _newPosition.tokenToBuy
        );
    }
}
