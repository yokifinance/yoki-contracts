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
        address[] memory core_assets_to_spend = new address[](3);
        core_assets_to_spend[0] = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; // DAI
        core_assets_to_spend[1] = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607; // USDC
        core_assets_to_spend[2] = 0x94b008aA00579c1307B0EF2c499aD98a8ce58e58; // USDT

        address[] memory core_assets_to_buy = new address[](5);
        core_assets_to_buy[0] = 0x68f180fcCe6836688e9084f035309E29Bf0A2095; // WBTC
        core_assets_to_buy[1] = 0x4200000000000000000000000000000000000042; // OP
        core_assets_to_buy[2] = 0x4200000000000000000000000000000000000006; // WETH
        core_assets_to_buy[3] = 0x73cb180bf0521828d8849bc8CF2B920918e23032; // USD+
        core_assets_to_buy[4] = 0xFdb794692724153d1488CcdBE0C56c252596735F; // LDO

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
