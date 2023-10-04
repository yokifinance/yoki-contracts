// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// TODO: use open-zepplin helper instead
import "@uniswap-periphery/contracts/libraries/TransferHelper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RPSV1 is Initializable, Ownable {
    bool public deactivated = false;
    address public constant TREASURY = 0x400d0dbd2240c8cF16Ee74E628a6582a42bb4f35;
    uint256 public constant MIN_FREQUENCY = 60;
    uint8 public constant FEE = 1; // commission %

    address public target;
    IERC20 public token;
    uint256 public amount;
    uint256 public frequency = MIN_FREQUENCY;

    uint256 public lastExecutionTimestamp = 0;

    event executed(
        address contractAddress,
        address executor,
        address target,
        uint256 amount,
        uint256 fee,
        uint256 nextExecutionTimestamp
    );
    event terminated(address contractAddress);

    // TODO: move to helpers
    function _checkIsERC20(address tokenAddress) internal view returns (bool) {
        try IERC20(tokenAddress).totalSupply() returns (uint256) {
            return true;
        } catch (bytes memory) {
            return false;
        }
    }

    function initialize(address newOwner, address target_, address tokenAddress, uint256 amount_, uint256 frequency_)
        public
        initializer
    {
        require(target != address(0), "RPS: Invalid target address");
        require(tokenAddress != address(0), "RPS: Invalid token address");
        require(_checkIsERC20(tokenAddress), "RPS: Provided token address is not ERC20");
        require(amount_ > 100, "RPS: Amount should be at least 100");
        require(frequency_ > MIN_FREQUENCY, "RPS: Frequency should be at least 1 minute");
        transferOwnership(newOwner);

        target = target_;
        token = IERC20(tokenAddress);
        amount = amount_;
        frequency = frequency_;
    }

    function canExecute() public view returns (bool) {
        require(!deactivated, "RPS: Subscription was deactivated");
        require(block.timestamp + 24 > lastExecutionTimestamp + frequency, "RPS: Too soon to execute");
        require(token.allowance(owner(), address(this)) > amount, "RPS: Allowance is too low");
        require(token.balanceOf(owner()) > amount, "RPS: User balance is too low");
        return true;
    }

    function execute() public returns (uint256 nextExectuionTimestamp) {
        require(canExecute(), "RPS: Can't execute");
        lastExecutionTimestamp = lastExecutionTimestamp + frequency;
        // if execute was not called in proper time-period - reset timer
        if (lastExecutionTimestamp + frequency < block.timestamp) {
            lastExecutionTimestamp = block.timestamp;
        }

        uint256 fee = (amount * FEE) / 100;
        uint256 amountToTransfer = amount - fee;
        TransferHelper.safeTransfer(address(token), TREASURY, fee);
        TransferHelper.safeTransfer(address(token), target, amountToTransfer);

        uint256 nextExecutionTimestamp = lastExecutionTimestamp + frequency;
        emit executed(address(this), address(msg.sender), target, amountToTransfer, fee, nextExecutionTimestamp);

        return nextExecutionTimestamp;
    }

    function terminate() public {
        require(msg.sender == target || msg.sender == owner(), "RPS: Forbidden");
        deactivated = true;
        emit terminated(address(this));
    }
}
