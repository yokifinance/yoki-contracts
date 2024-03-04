// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IAssetsWhitelist {
    event WhitelistedAssetToSpend(address assetToSpend);
    event WhitelistedAssetToBuy(address assetToBuy);
    event RemovedAssetToSpend(address assetToSpend);
    event RemovedAssetToBuy(address assetToBuy);

    function checkIfWhitelisted(address assetToSpend, address assetToBuy) external view returns (bool);
    function removeAssetToSpend(address assetToSpend) external;
    function removeAssetToBuy(address assetToBuy) external;
    function whitelistAssetToSpend(address assetToSpend) external;
    function whitelistAssetToBuy(address assetToBuy) external;
}
