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
        address[] memory core_assets_to_spend = new address[](4);
        core_assets_to_spend[0] = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063; // DAI
        core_assets_to_spend[1] = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC
        core_assets_to_spend[2] = 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // USDT
        core_assets_to_spend[3] = 0xE111178A87A3BFf0c8d18DECBa5798827539Ae99; // EURS

        address[] memory core_assets_to_buy = new address[](3);
        core_assets_to_buy[0] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // WMATIC
        core_assets_to_buy[1] = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619; // WETH
        core_assets_to_buy[2] = 0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6; // WBTC

        console.log("Deploying whitelist");
        AssetsWhitelist whitelist = (new DeployAssetsWhitelist()).run(core_assets_to_spend, core_assets_to_buy);
        console.log("Whitelist deployed: ", address(whitelist));

        console.log("Deploying DCAV3 Implementation for later cloning");
        DCAV3 dcaImp = (new DeployDCAV3()).run();
        console.log("DCAV3 deployed: ", address(dcaImp));

        console.log("Deploying factory");
        DCAV3Factory factory = (new DeployDCAV3Factory()).run(address(whitelist), address(dcaImp));
        console.log("Factory deployed: ", address(factory));
    }
}
