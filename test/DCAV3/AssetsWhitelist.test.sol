pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./helpers/AssetsHelper.sol";
import "@DCA/dependencies/AssetsWhitelist.sol";

contract AssetsWhitelistTest is Test {
    AssetsHelper public assetsHelper;
    address[] public assetsToSpend;
    address[] public assetsToBuy;
    address public notListedAsset;
    AssetsWhitelist assetsWhitelist;
    address internal admin;
    address internal user;
    address internal worker;
    address newAssetToSpend;
    address newAssetToBuy;
    address removedSpendAsset;
    address removedBuyAsset;

    function setUp() public {
        assetsHelper = new AssetsHelper(2);
        address[] memory assetsAddresses = assetsHelper.getAssetsAddresses();
        assetsToSpend = assetsAddresses;
        assetsToBuy = assetsAddresses;
        worker = makeAddr("worker");

        notListedAsset = address(assetsHelper.generateAsset("UnlistedAsset", "UA"));
        assetsWhitelist = new AssetsWhitelist(worker, assetsToSpend, assetsToBuy);
        admin = assetsWhitelist.TREASURY();
        user = makeAddr("user");

        newAssetToSpend = address(assetsHelper.generateAsset("New asset: sell", "NAS"));
        newAssetToBuy = address(assetsHelper.generateAsset("New asset: buy", "NAB"));
        removedSpendAsset = assetsToSpend[0];
        removedBuyAsset = assetsToSpend[0];
    }

    function test_checkWhitelisted() public {
        assertTrue(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], assetsToBuy[0]));
        assertFalse(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], notListedAsset));
        assertFalse(assetsWhitelist.checkIfWhitelisted(notListedAsset, assetsToBuy[0]));
    }

    function test_addWhitelistSpend() public {
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

        assertFalse(assetsWhitelist.checkIfWhitelisted(newAssetToBuy, newAssetToBuy));

        vm.prank(admin);
        assetsWhitelist.whitelistAssetToBuy(newAssetToBuy);
        assertTrue(assetsWhitelist.checkIfWhitelisted(assetToSpend, newAssetToBuy));
        // make sure that if we allow buying - spending is not whitelisted too
        assertFalse(assetsWhitelist.checkIfWhitelisted(newAssetToBuy, assetToSpend));
    }

    function test_removeWhitelistSpend() public {
        assertTrue(assetsWhitelist.checkIfWhitelisted(removedSpendAsset, assetsToBuy[0]));
        vm.prank(admin);
        assetsWhitelist.removeAssetToSpend(removedSpendAsset);
        assertFalse(assetsWhitelist.checkIfWhitelisted(removedSpendAsset, assetsToBuy[0]));
    }

    function test_removeWhitelistBuy() public {
        assertTrue(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], removedBuyAsset));
        vm.prank(admin);
        assetsWhitelist.removeAssetToBuy(removedBuyAsset);
        assertFalse(assetsWhitelist.checkIfWhitelisted(assetsToSpend[0], removedBuyAsset));
    }

    function test_revertIfUnauthorizedWhitelistAssetToSpend() public {
        vm.startPrank(user);
        vm.expectRevert("Must have admin role to edit the whitelist");
        assetsWhitelist.whitelistAssetToSpend(newAssetToSpend);
    }

    function test_revertIfUnauthorizedwhitelistAssetToBuy() public {
        vm.startPrank(user);
        vm.expectRevert("Must have admin role to edit the whitelist");
        assetsWhitelist.whitelistAssetToBuy(newAssetToSpend);
    }

    function test_revertIfUnauthorizeRemoveAssetToSpend() public {
        vm.startPrank(user);
        vm.expectRevert("Must have admin role to edit the whitelist");
        assetsWhitelist.removeAssetToSpend(newAssetToSpend);
    }

    function test_revertIfUnauthorizedRemoveAssetToBuy() public {
        vm.startPrank(user);
        vm.expectRevert("Must have admin role to edit the whitelist");
        assetsWhitelist.removeAssetToBuy(newAssetToSpend);
    }

    function test_addNewAdmin() public {
        // Check if the admin has the DEFAULT_ADMIN_ROLE
        assertTrue(
            assetsWhitelist.hasRole(assetsWhitelist.DEFAULT_ADMIN_ROLE(), admin),
            "Admin does not have the DEFAULT_ADMIN_ROLE"
        );

        // Now, grant the ADMIN_ROLE to the worker
        vm.startPrank(admin);

        assetsWhitelist.grantRole(assetsWhitelist.ADMIN_ROLE(), user);
        assertTrue(assetsWhitelist.hasRole(assetsWhitelist.ADMIN_ROLE(), user));
    }

    function test_removeAdmin() public {
        vm.startPrank(admin);

        assetsWhitelist.grantRole(assetsWhitelist.ADMIN_ROLE(), user);
        assetsWhitelist.revokeRole(assetsWhitelist.ADMIN_ROLE(), user);
        assertFalse(assetsWhitelist.hasRole(assetsWhitelist.ADMIN_ROLE(), user));
    }
}
