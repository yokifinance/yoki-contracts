pragma solidity >=0.8.15;

import "forge-std/Test.sol";
import {IDCA} from "interfaces/IDCA.sol";
import {ISwapRouter} from "@uniswap-periphery/contracts/interfaces/ISwapRouter.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {DCAV3} from "../src/strategies/DcaV3.sol";
import "./helpers/AssetsHelper.sol";
import "../src/dependencies/AssetsWhitelist.sol";

// simulate 1 to 1 ratio at all times
contract FakeSwapRouter is ISwapRouter {
    event SwapExecuted(address assetIn, address assetOut, address user, uint256 amountSpent, uint256 amountAcquired);
    event MultiHopSwapExecuted(bytes path, address user, uint256 amountSpent, uint256 amountAcquired);
    constructor() {}

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut) {
        emit SwapExecuted(params.tokenIn, params.tokenOut, params.recipient, params.amountIn, params.amountIn);
        return params.amountIn;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut) {
        emit MultiHopSwapExecuted(params.path, params.recipient, params.amountIn, params.amountIn);
        return params.amountIn;
    }

    // not used
    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {}
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn) {}
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn) {}
}

contract DcaV3Test is Test {
    AssetsHelper public assetsHelper;
    AssetsWhitelist public assetsWhiteList;
    DCAV3 public DCA;
    IDCA.Position public initialPosition;
    address internal user;
    address internal worker;
    FakeSwapRouter internal fakeRouter;

    // https://book.getfoundry.sh/cheatcodes/expect-emit
    /*
        If the event is not available in the current scope (e.g. if we are using an interface, or an external smart contract), 
        we can define the event ourselves with an identical event signature.
    */
    event PurchaseExecuted(
        uint256 positionIndex, address tokenSpent, address tokenAcquired, uint256 amountSpent, uint256 amountAcquired
    );
    event SwapExecuted(address assetIn, address assetOut, address user, uint256 amountSpent, uint256 amountAcquired);
    event MultiHopSwapExecuted(bytes path, address user, uint256 amountSpent, uint256 amountAcquired);

    function setUp() public {
        assetsHelper = new AssetsHelper(2);
        address[] memory assetsAddresses = assetsHelper.getAssetsAddresses();

        user = makeAddr("user");
        worker = makeAddr("worker");

        vm.prank(user);
        vm.deal(user, 1 ether);

        assetsWhiteList = new AssetsWhitelist(assetsAddresses, assetsAddresses);
        DCA = new DCAV3();
        initialPosition = IDCA.Position({
            beneficiary: user,
            executor: worker,
            singleSpendAmount: 1,
            tokenToSpend: assetsAddresses[0],
            tokenToBuy: assetsAddresses[1],
            lastPurchaseTimestamp: 1
        });
        fakeRouter = new FakeSwapRouter();
        DCA.initialize(assetsWhiteList, address(fakeRouter), user, initialPosition);
        
        // Open second position
        vm.prank(user);
        DCA.openPosition(
            IDCA.Position({
                beneficiary: user,
                executor: worker,
                singleSpendAmount: 100000, // 1 USDT
                tokenToSpend: assetsAddresses[0],
                tokenToBuy: assetsAddresses[1],
                lastPurchaseTimestamp: 1
            })
        );
    }

    function test_singlePurchase() public {
        uint256 amountIn = 1;
        ERC20 assetIn = assetsHelper.assets(0);
        ERC20 assetOut = assetsHelper.assets(1);
        vm.warp(block.timestamp + DCA.EXECUTION_COOLDOWN());
        assetsHelper.dealTokens(assetIn, user, 1);

        vm.prank(user);
        assetIn.approve(address(DCA), 1);

        vm.expectEmit(address(fakeRouter));
        emit SwapExecuted(address(assetIn), address(assetOut), address(user), amountIn, amountIn);

        vm.expectEmit(address(DCA));
        emit PurchaseExecuted(0, address(assetIn), address(assetOut), amountIn, amountIn);

        vm.prank(worker);
        DCA.executeSinglePurchase(
            0,
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(assetIn),
                tokenOut: address(assetOut),
                fee: 0,
                recipient: user,
                deadline: 0, // not used in test
                amountIn: amountIn,
                amountOutMinimum: amountIn,
                sqrtPriceLimitX96: 0 // not used in test
            })
        );
    }

    function test_multiplePurchase() public {
        uint256 amountIn = 1;
        ERC20 assetIn = assetsHelper.assets(0);
        ERC20 assetOut = assetsHelper.assets(1);
        uint24 fee = 0;
        bytes memory swapPath = abi.encodePacked(address(assetIn), fee, address(assetOut));

        vm.warp(block.timestamp + DCA.EXECUTION_COOLDOWN());
        assetsHelper.dealTokens(assetIn, user, 1);

        vm.prank(user);
        assetIn.approve(address(DCA), amountIn);
        
        vm.expectEmit(address(fakeRouter));
        emit MultiHopSwapExecuted(swapPath, address(user), amountIn, amountIn);

        vm.expectEmit(address(DCA));
        emit PurchaseExecuted(0, address(assetIn), address(assetOut), amountIn, amountIn);

        vm.prank(worker);
        DCA.executeMultihopPurchase(
            0,
            ISwapRouter.ExactInputParams({
                path: swapPath,
                recipient: user,
                deadline: 0, // not used in test
                amountIn: amountIn,
                amountOutMinimum: 1 // not used in test
            })
        );
    }

    function test_openPosition() public {
        address[] memory assetsAddresses = assetsHelper.getAssetsAddresses();
        address tokenToSpend = assetsAddresses[0];
        address tokenToBuy = assetsAddresses[1];
        uint256 singleSpendAmount = 1;
        vm.prank(user);
        DCA.openPosition(
            IDCA.Position({
                beneficiary: user,
                executor: worker,
                singleSpendAmount: 1,
                tokenToSpend: tokenToSpend,
                tokenToBuy: tokenToBuy,
                lastPurchaseTimestamp: 1
            })
        );
        IDCA.Position memory newPosition = DCA.getPosition(0);
        assertEq(newPosition.beneficiary, user);
        assertEq(newPosition.executor, worker);
        assertEq(newPosition.singleSpendAmount, singleSpendAmount);
        assertEq(newPosition.tokenToSpend, tokenToSpend);
        assertEq(newPosition.tokenToBuy, tokenToBuy);
    }

    function test_setSingleSpendAmount() public {
        uint256 newSingleSpendAmount = 1000;
        IDCA.Position memory targetPosition = DCA.getPosition(0);
        vm.prank(user);
        DCA.setSingleSpendAmount(0, newSingleSpendAmount);
        IDCA.Position memory updatedPosition = DCA.getPosition(0);
        assertNotEq(targetPosition.singleSpendAmount, updatedPosition.singleSpendAmount);
        assertEq(updatedPosition.singleSpendAmount, newSingleSpendAmount);
    }

    function test_setBeneficiary() public {
        address newBeneficiary = makeAddr("new beneficiary");
        vm.prank(user);
        DCA.setBeneficiary(0, newBeneficiary);
        IDCA.Position memory updatedPosition = DCA.getPosition(0);
        assertEq(updatedPosition.beneficiary, newBeneficiary);
    }

    function test_retrieveFunds() public {
        uint256 tokensAmount = 10;
        address recipient = makeAddr("recipient");
        ERC20 targetAsset = assetsHelper.assets(0);
        assetsHelper.dealTokens(targetAsset, user, tokensAmount);
        assertEq(targetAsset.balanceOf(user), tokensAmount);
        assertEq(targetAsset.balanceOf(recipient), 0);

        address[] memory assetsToRetrieve = new address[](1);
        assetsToRetrieve[0] = address(targetAsset);
        vm.prank(user);
        targetAsset.transfer(address(DCA), tokensAmount);
        vm.prank(user);
        DCA.retrieveFunds(assetsToRetrieve, recipient);

        assertEq(targetAsset.balanceOf(recipient), tokensAmount);
        assertEq(targetAsset.balanceOf(user), 0);
    }

    function test_initialtCommissionFeeMultiplier() public {
        vm.prank(user);
        uint256 initialtCommissionFeeMultiplier = 0;
        assertEq(DCA.commissionFeeMultiplier(), initialtCommissionFeeMultiplier);
    }

    function test_revertIfsetCommissionFeeMultiplierFromNotAdmin() public {
        address notAdmin = makeAddr("notAdmin");
        vm.prank(notAdmin);
        vm.expectRevert("Must have admin role to set commission fee");
        DCA.setCommissionFeeMultiplier(1);
    }

    function test_setCommissionFeeMultiplierFromAdmin() public {
        address admin = 0x400d0dbd2240c8cF16Ee74E628a6582a42bb4f35;
        vm.prank(admin);
        DCA.setCommissionFeeMultiplier(5);
        assertEq(DCA.commissionFeeMultiplier(), 5);
    }

    function test_handleFees() public {
        address vault = 0x400d0dbd2240c8cF16Ee74E628a6582a42bb4f35;
        address admin = 0x400d0dbd2240c8cF16Ee74E628a6582a42bb4f35;

        uint256 amountIn = 100000;
        ERC20 assetIn = assetsHelper.assets(0);

        ERC20 assetOut = assetsHelper.assets(1);
        uint24 fee = 0;
        uint256 positionIndex = 1; 
        bytes memory swapPath = abi.encodePacked(address(assetIn), fee, address(assetOut));

        vm.warp(block.timestamp + DCA.EXECUTION_COOLDOWN());
        assetsHelper.dealTokens(assetIn, user, 100000);

        vm.prank(user);
        assetIn.approve(address(DCA), amountIn);

        vm.prank(admin);
        DCA.setCommissionFeeMultiplier(50); // 5 %
        
        vm.prank(worker);
        DCA.executeMultihopPurchase(
            positionIndex,
            ISwapRouter.ExactInputParams({
                path: swapPath,
                recipient: user,
                deadline: 0, // not used in test
                amountIn: amountIn,
                amountOutMinimum: 1 // not used in test
            })
        );
        assertEq(assetIn.balanceOf(vault), 5000); // 5 % of amountIn = 5000 

    }
}

    