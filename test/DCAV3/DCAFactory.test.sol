pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "./helpers/AssetsHelper.sol";
import "@DCA/interfaces/IDCA.sol";
import "@DCA/strategies/DcaV3.sol";
import "@DCA/factories/DCAV3Factory.sol";
import "@DCA/dependencies/AssetsWhitelist.sol";

contract DCAFactoryTest is Test {
    AssetsHelper public assetsHelper;
    address[] public assets;
    AssetsWhitelist public assetsWhitelist;
    address public owner;
    address public worker;
    IDCA.Position public initialPosition;
    DCAV3Factory public factory;

    function setUp() public {
        owner = makeAddr("owner");
        worker = makeAddr("worker");
        assetsHelper = new AssetsHelper(2);
        assets = assetsHelper.getAssetsAddresses();
        assetsWhitelist = new AssetsWhitelist(worker, assets, assets);
        initialPosition = IDCA.Position(owner, worker, 10, assets[0], assets[1], 0);
        DCAV3 dcaImp = new DCAV3();
        factory = new DCAV3Factory(worker, address(assetsWhitelist), address(dcaImp));
    }

    function test_factoryCreateDCA() public {
        vm.prank(owner);
        address dcaAddress = factory.createDCA(owner, initialPosition);
        IDCA dca = DCAV3(dcaAddress);
        // error thrown when allPositionsLength() called
        assertTrue(dca.allPositionsLength() > 0);
    }
}
