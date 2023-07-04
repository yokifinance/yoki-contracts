pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./helpers/AssetsHelper.sol";
import "../src/dependencies/AssetsWhitelist.sol";

contract AssetsWhitelistTest is Test {
    AssetsHelper public assetsHelper;
    address[] public assetsToSpend;
    address[] public assetsToBuy;
    address public notListedAsset;

    function setUp() public {
        assetsHelper = new AssetsHelper(2);
        address[] memory assetsAddresses = assetsHelper.getAssetsAddresses();
        assetsToSpend = assetsAddresses;
        assetsToBuy = assetsAddresses;
        notListedAsset = address(assetsHelper.generateAsset("UnlistedAsset", "UA"));
    }

    function test_checkWhitelisted() public {
        AssetsWhitelist assetsWhitelist = new AssetsWhitelist(assetsToSpend, assetsToBuy);
        assertTrue(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], assetsToBuy[0]));
        assertFalse(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], notListedAsset));
        assertFalse(assetsWhitelist.checkIfWhitelisted(notListedAsset, assetsToBuy[0]));
    }

    function test_addWhitelistSpend() public {
        AssetsWhitelist assetsWhitelist = new AssetsWhitelist(assetsToSpend, assetsToBuy);
        address newAssetToSpend = address(assetsHelper.generateAsset("New asset: sell", "NAS"));
        address assetToBuy = assetsToBuy[0];

        assertFalse(assetsWhitelist.checkIfWhitelisted(newAssetToSpend, newAssetToSpend));
        assetsWhitelist.whitelistAssetToSpend(newAssetToSpend);
        assertTrue(assetsWhitelist.checkIfWhitelisted(newAssetToSpend, assetToBuy));

        // make sure that if we allow spending - buying is not whitelisted too
        assertFalse(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], newAssetToSpend));
    }

    function test_addWhitelistBuy() public {
        AssetsWhitelist assetsWhitelist = new AssetsWhitelist(assetsToSpend, assetsToBuy);
        address assetToSpend = assetsToSpend[0];
        address newAssetToBuy = address(assetsHelper.generateAsset("New asset: buy", "NAB"));

        assertFalse(assetsWhitelist.checkIfWhitelisted(newAssetToBuy, newAssetToBuy));

        assetsWhitelist.whitelistAssetToBuy(newAssetToBuy);
        assertTrue(assetsWhitelist.checkIfWhitelisted(assetToSpend, newAssetToBuy));
        // make sure that if we allow buying - spending is not whitelisted too
        assertFalse(assetsWhitelist.checkIfWhitelisted(newAssetToBuy, assetToSpend));
    }

    function test_removeWhitelistSpend() public {
        AssetsWhitelist assetsWhitelist = new AssetsWhitelist(assetsToSpend, assetsToBuy);

        address removedSpendAsset = assetsToSpend[0];
        assertTrue(assetsWhitelist.checkIfWhitelisted(removedSpendAsset, assetsToBuy[0]));

        assetsWhitelist.removeAssetToSpend(removedSpendAsset);
        assertFalse(assetsWhitelist.checkIfWhitelisted(removedSpendAsset, assetsToBuy[0]));
    }

    function test_removeWhitelistBuy() public {
        AssetsWhitelist assetsWhitelist = new AssetsWhitelist(assetsToSpend, assetsToBuy);

        address removedBuyAsset = assetsToSpend[0];
        assertTrue(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], removedBuyAsset));

        assetsWhitelist.removeAssetToBuy(removedBuyAsset);
        assertFalse(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], removedBuyAsset));
    }
}
