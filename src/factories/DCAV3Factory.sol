// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma abicoder v2;

import "interfaces/IDCA.sol";
import "interfaces/IAssetsWhitelist.sol";
import "../libraries/Path.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@uniswap-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap-periphery/contracts/libraries/TransferHelper.sol";

contract DCAV3Factory {
    using Path for bytes;

    address public assetsWhitelist;
    address public dcaImpl;

    address public constant SWAP_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    event DcaDeployed(address indexed newDcaAddress, address indexed newOwner);

    constructor(address assetsWhitelist_, address dcaImpl_) {
        require(assetsWhitelist_ != address(0));
        require(dcaImpl_ != address(0));
        assetsWhitelist = assetsWhitelist_;
        dcaImpl = dcaImpl_;
    }

    function createDCA(address newOwner, IDCA.Position calldata initialPosition)
        external
        returns (address newDcaProxy)
    {
        address tokenIn = initialPosition.tokenToSpend;
        newDcaProxy = _deployDCA(newOwner, initialPosition);
        TransferHelper.safeApprove(tokenIn, newDcaProxy, type(uint256).max);

        return newDcaProxy;
    }

    function _deployDCA(address _newOwner, IDCA.Position calldata _initialPosition) internal returns (address) {
        address proxy = Clones.clone(dcaImpl);

        IDCA(proxy).initialize(IAssetsWhitelist(assetsWhitelist), SWAP_ROUTER, _newOwner, _initialPosition);

        emit DcaDeployed(proxy, _newOwner);

        return proxy;
    }
}
