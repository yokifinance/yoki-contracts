pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./helpers/AssetsHelper.sol";
import "../src/dependencies/AssetsWhitelist.sol";

contract AssetsWhitelistTest is Test {
    AssetsHelper public assetsHelper;
    address[] public assetsToSpend;
    address[] public assetsToBuy;
    address public notListedAsset;
    AssetsWhitelist assetsWhitelist;
    address admin;

    function setUp() public {
        assetsHelper = new AssetsHelper(2);
        address[] memory assetsAddresses = assetsHelper.getAssetsAddresses();
        assetsToSpend = assetsAddresses;
        assetsToBuy = assetsAddresses;
        notListedAsset = address(assetsHelper.generateAsset("UnlistedAsset", "UA"));
        assetsWhitelist = new AssetsWhitelist(assetsToSpend, assetsToBuy);
        admin = assetsWhitelist.TREASURY();
    }

    function test_checkWhitelisted() public {
        assertTrue(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], assetsToBuy[0]));
        assertFalse(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], notListedAsset));
        assertFalse(assetsWhitelist.checkIfWhitelisted(notListedAsset, assetsToBuy[0]));
    }

    function test_addWhitelistSpend() public {
        address newAssetToSpend = address(assetsHelper.generateAsset("New asset: sell", "NAS"));
        address assetToBuy = assetsToBuy[0];

        assertFalse(assetsWhitelist.checkIfWhitelisted(newAssetToSpend, newAssetToSpend));

        vm.prank(admin);
        assetsWhitelist.whitelistAssetToSpend(newAssetToSpend);
        assertTrue(assetsWhitelist.checkIfWhitelisted(newAssetToSpend, assetToBuy));

        // make sure that if we allow spending - buying is not whitelisted too
        assertFalse(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], newAssetToSpend));
    }

    function test_addWhitelistBuy() public {
        address assetToSpend = assetsToSpend[0];
        address newAssetToBuy = address(assetsHelper.generateAsset("New asset: buy", "NAB"));

        assertFalse(assetsWhitelist.checkIfWhitelisted(newAssetToBuy, newAssetToBuy));
    
        vm.prank(admin);
        assetsWhitelist.whitelistAssetToBuy(newAssetToBuy);
        assertTrue(assetsWhitelist.checkIfWhitelisted(assetToSpend, newAssetToBuy));
        // make sure that if we allow buying - spending is not whitelisted too
        assertFalse(assetsWhitelist.checkIfWhitelisted(newAssetToBuy, assetToSpend));
    }

    function test_removeWhitelistSpend() public {
        address removedSpendAsset = assetsToSpend[0];
        assertTrue(assetsWhitelist.checkIfWhitelisted(removedSpendAsset, assetsToBuy[0]));
    
        vm.prank(admin);
        assetsWhitelist.removeAssetToSpend(removedSpendAsset);
        assertFalse(assetsWhitelist.checkIfWhitelisted(removedSpendAsset, assetsToBuy[0]));
    }

    function test_removeWhitelistBuy() public {
        address removedBuyAsset = assetsToSpend[0];
        assertTrue(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], removedBuyAsset));
    
        vm.prank(admin);
        assetsWhitelist.removeAssetToBuy(removedBuyAsset);
        assertFalse(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], removedBuyAsset));
    }

    function test_unauthorizedAccessAttempt() public {
        address notAdmin = makeAccount("notAdmin").addr;
        address newAssetToSpend = address(assetsHelper.generateAsset("New asset: sell", "NAS"));
        address newAssetToBuy = address(assetsHelper.generateAsset("New asset: buy", "NAB"));
        address removedSpendAsset = assetsToSpend[0];
        address removedBuyAsset = assetsToSpend[0];

        vm.startPrank(notAdmin);

        vm.expectRevert("Must have admin role to edit the whitelist");
        assetsWhitelist.whitelistAssetToSpend(newAssetToSpend);

        vm.expectRevert("Must have admin role to edit the whitelist");
        assetsWhitelist.whitelistAssetToBuy(newAssetToBuy);

        vm.expectRevert("Must have admin role to edit the whitelist");
        assetsWhitelist.removeAssetToSpend(removedSpendAsset);

        vm.expectRevert("Must have admin role to edit the whitelist");
        assetsWhitelist.removeAssetToBuy(removedBuyAsset);


    }
}
