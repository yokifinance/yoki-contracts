// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {DeployAssetsWhitelist} from "../01_DeployAssetsWhitelist.s.sol";
import {DeployDCAV3} from "../02_DeployDCAV3.s.sol";
import {DeployDCAV3Factory} from "../03_DeployDCAV3Factory.s.sol";

import {AssetsWhitelist} from "../../src/dependencies/AssetsWhitelist.sol";
import {DCAV3} from "../../src/strategies/DcaV3.sol";
import {DCAV3Factory} from "../../src/factories/DCAV3Factory.sol";

contract DeployAll is Script {
    function run() external {
        // pancake swap v2
        address swapRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        address[] memory core_assets_to_spend = new address[](2);
        core_assets_to_spend[0] = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD
        core_assets_to_spend[1] = 0x55d398326f99059fF775485246999027B3197955; // USDT

        address[] memory core_assets_to_buy = new address[](3);
        core_assets_to_buy[0] = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8; // ETH
        core_assets_to_buy[1] = 0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c; // BTCB
        core_assets_to_buy[2] = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // WBNB

        address worker = 0x79dAe73Ec88a11FA4B9381Fe92865a1EAE5f3125; // dev
        // address worker = 0x79dAe73Ec88a11FA4B9381Fe92865a1EAE5f3125; // stage
        // address worker = 0x31F5c1B1fF78AF6FB721cD1376f1B7D69929A794; // prod

        console.log("Deploying whitelist");
        AssetsWhitelist whitelist = (new DeployAssetsWhitelist()).run(worker, core_assets_to_spend, core_assets_to_buy);
        console.log("Whitelist deployed: ", address(whitelist));

        console.log("Deploying DCAV3 Implementation for later cloning");
        DCAV3 dcaImp = (new DeployDCAV3()).run();
        console.log("DCAV3 deployed: ", address(dcaImp));

        console.log("Deploying factory");
        DCAV3Factory factory = (new DeployDCAV3Factory()).run(swapRouter, address(whitelist), address(dcaImp));
        console.log("Factory deployed: ", address(factory));
    }
}
