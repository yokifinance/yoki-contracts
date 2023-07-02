// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/IAssetsWhitelist.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AssetsWhitelist is IAssetsWhitelist, Ownable {
    mapping(address => bool) internal _whitelistedToSpend;
    mapping(address => bool) internal _whitelistedToBuy;

    constructor(
        address[] memory assetsToSpend_,
        address[] memory assetsToBuy_
    ) {
        uint256 len = assetsToSpend_.length;

        for (uint i = 0; i < len; i++) {
            _whitelistAssetToSpend(assetsToSpend_[i]);
        }

        len = assetsToBuy_.length;

        for (uint i = 0; i < len; i++) {
            _whitelistAssetToBuy(assetsToBuy_[i]);
        }
    }

    function checkIfWhitelisted(address assetToSpend, address assetToBuy) external view override returns (bool) {
        if (_whitelistedToSpend[assetToSpend] && _whitelistedToBuy[assetToBuy])
            return true;
        return false;
    }

    function whitelistAssetToSpend(address assetToSpend) external override onlyOwner {
        _whitelistAssetToSpend(assetToSpend);
    }

    function whitelistAssetToBuy(address assetToBuy) external override onlyOwner {
        _whitelistAssetToBuy(assetToBuy);
    }

    function removeAssetToSpend(address assetToSpend) external override onlyOwner {
        require(_whitelistedToSpend[assetToSpend]);
        _whitelistedToSpend[assetToSpend] = false;

        emit RemovedAssetToSpend(assetToSpend);
    }

    function removeAssetToBuy(address assetToBuy) external override onlyOwner {
        require(_whitelistedToBuy[assetToBuy]);
        _whitelistedToBuy[assetToBuy] = false;

        emit RemovedAssetToBuy(assetToBuy);
    }

    function _whitelistAssetToSpend(
        address _assetToSpend
    ) internal {
        require(_assetToSpend != address(0));
        require(!_whitelistedToSpend[_assetToSpend]);

        _whitelistedToSpend[_assetToSpend] = true;

        emit WhitelistedAssetToSpend(_assetToSpend);
    }

    function _whitelistAssetToBuy(
        address _assetToBuy
    ) internal {
        require(_assetToBuy != address(0));
        require(!_whitelistedToBuy[_assetToBuy]);

        _whitelistedToBuy[_assetToBuy] = true;

        emit WhitelistedAssetToBuy(_assetToBuy);
    }
}
