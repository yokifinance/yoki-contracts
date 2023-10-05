// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {DeployAssetsWhitelist} from "../01_DeployAssetsWhitelist.s.sol";
import {DeployDCAV3} from "../02_DeployDCAV3.s.sol";
import {DeployDCAV3Factory} from "../03_DeployDCAV3Factory.s.sol";

import {AssetsWhitelist} from "@DCA/dependencies/AssetsWhitelist.sol";
import {DCAV3} from "@DCA/strategies/DcaV3.sol";
import {DCAV3Factory} from "@DCA/factories/DCAV3Factory.sol";

contract DeployAll is Script {
    function run() external {
        address swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        address[] memory core_assets_to_spend = new address[](4);
        core_assets_to_spend[0] = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063; // DAI
        core_assets_to_spend[1] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC
        core_assets_to_spend[2] = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // USDT
        core_assets_to_spend[3] = 0xE111178A87A3BFf0c8d18DECBa5798827539Ae99; // EURS

        address[] memory core_assets_to_buy = new address[](7);
        core_assets_to_buy[0] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // WMATIC
        core_assets_to_buy[1] = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619; // WETH
        core_assets_to_buy[2] = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6; // WBTC
        core_assets_to_buy[3] = 0xB9638272aD6998708de56BBC0A290a1dE534a578; // IQ
        core_assets_to_buy[4] = 0xF689E85988d3a7921E852867CE49F53388985E6d; // MobiFi
        core_assets_to_buy[5] = 0x3A58a54C066FdC0f2D55FC9C89F0415C92eBf3C4; // stMatic
        core_assets_to_buy[6] = 0xC3C7d422809852031b44ab29EEC9F1EfF2A58756; // LDO

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
