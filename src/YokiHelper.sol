// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library YokiHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Yoki: STF failed");
    }

    /// @notice Checck if provided address is ERC20 token
    /// @param token The contract address of the ERC20 token to be checked
    /// @return true if ERC20 or false otherwise
    function isERC20(address token) internal view returns (bool) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSignature("totalSupply()"));
        return success && (data.length > 0);
    }
}
