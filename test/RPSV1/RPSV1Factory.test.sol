pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@RPS/RPSV1Factory.sol";
import "@RPS/RPSV1.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../helpers/AssetsHelper.sol";

contract RPSV1FactoryTest is Test {
    RPSV1Factory factory;
    AssetsHelper assetsHelper;
    address assetAddress;
    address public owner;
    address[] public admins;

    event RPSCreated(address indexed contractAddress, string merchantName);

    function setUp() public {
        owner = makeAddr("owner");
        address admin = makeAddr("admin");
        assetsHelper = new AssetsHelper(1);
        assetAddress = assetsHelper.getAssetsAddresses()[0];
        RPSV1 rpsImp = new RPSV1();
        admins = new address[](1);
        admins[0] = admin;
        vm.prank(owner);
        factory = new RPSV1Factory(address(rpsImp), admins);
    }

    function test_RPSV1Factory_creaRPS_restricted() public {
        address trickster = makeAddr("trickster");
        vm.prank(trickster);
        vm.expectRevert("RPS: Forbidden");
        factory.createRPS("Trickster", trickster, assetAddress, 100, 60, 100);
    }

    function test_RPSV1Factory_createRPS_validations() public {
        string memory merchantName = "Merchant";
        address target = owner;
        address tokenAddress = assetAddress;
        uint256 subscriptionCost = 100;
        uint256 frequency = 36000;
        uint8 fee = 3;
        vm.startPrank(owner);

        vm.expectRevert("RPS: Invalid settlement address");
        factory.createRPS(merchantName, address(0), tokenAddress, subscriptionCost, frequency, fee);

        vm.expectRevert("RPS: Invalid token address");
        factory.createRPS(merchantName, target, address(0), subscriptionCost, frequency, fee);

        vm.expectRevert("RPS: Provided token address is not ERC20");
        factory.createRPS(merchantName, target, owner, subscriptionCost, frequency, fee);

        vm.expectRevert("RPS: Subscription cost should be at least 1");
        factory.createRPS(merchantName, target, tokenAddress, 0, frequency, fee);

        vm.expectRevert("RPS: Frequency should be at least 1 minute");
        factory.createRPS(merchantName, target, tokenAddress, subscriptionCost, 59, fee);

        vm.expectRevert("RPS: Processing fee must be less than 100 (10%)");
        factory.createRPS(merchantName, target, tokenAddress, subscriptionCost, frequency, 101);
    }

    function test_RPSV1Factory_createRPS() public {
        string memory merchantName = "Merchant";
        address merchantAddress = owner;
        address tokenAddress = assetAddress;
        uint256 subscriptionCost = 100;
        uint256 frequency = 36000;
        uint8 fee = 3;
        vm.prank(owner);
        factory.createRPS(merchantName, merchantAddress, tokenAddress, subscriptionCost, frequency, fee);
    }
}
