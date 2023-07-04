pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "interfaces/IDCA.sol";
import "./helpers/AssetsHelper.sol";
import "../src/strategies/DcaV3.sol";
import "../src/factories/DCAV3Factory.sol";
import "../src/dependencies/AssetsWhitelist.sol";

contract DCAFactoryTest is Test {
    AssetsHelper public assetsHelper;
    address[] public assets;
    AssetsWhitelist public assetsWhitelist;
    address public owner;
    IDCA.Position public initialPosition;
    DCAV3Factory public factory;

    function setUp() public {
        assetsHelper = new AssetsHelper(2);
        assets = assetsHelper.getAssetsAddresses();
        assetsWhitelist = new AssetsWhitelist(assets, assets);
        owner = makeAccount("owner").addr;
        address worker = makeAccount("worker").addr;
        initialPosition = IDCA.Position(owner, worker, 10, assets[0], assets[1], 0);
        address dcaImp = address(0xf52Aea45dFDE4669C73010D4C47E9e0c75E5c8ca); // TODO: figure out what contract this is
        factory = new DCAV3Factory(address(assetsWhitelist), dcaImp);
    }

    function test_factoryCreateDCA() public {
        vm.prank(owner);
        address dcaAddress = factory.createDCA(owner, initialPosition);
        IDCA dca = DCAV3(dcaAddress);
        // error thrown when allPositionsLength() called
        assertTrue(dca.allPositionsLength() > 0);
    }
}