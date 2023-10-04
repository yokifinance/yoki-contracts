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
        // fakerouter
        address swapRouter = 0x6c832ea9E6e31B4a88A03B00B809c4584C095d67;
        address[] memory core_assets_to_spend = new address[](2);
        core_assets_to_spend[0] = 0x0f81dB3cE47e70029060Da8FcA13996cFc2A1075; // FBUSD
        core_assets_to_spend[1] = 0x656A4fcCb761B5382ac2C6607D07b85719b9FF3C; // FBTCB

        address[] memory core_assets_to_buy = new address[](2);
        core_assets_to_buy[0] = 0x0f81dB3cE47e70029060Da8FcA13996cFc2A1075; // FBUSD
        core_assets_to_buy[1] = 0x656A4fcCb761B5382ac2C6607D07b85719b9FF3C; // FBTCB

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
