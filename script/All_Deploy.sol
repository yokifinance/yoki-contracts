// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {DeployAssetsWhitelist} from "./01_DeployAssetsWhitelist.s.sol";
import {DeployDCAV3} from "./02_DeployDCAV3.s.sol";
import {DeployDCAV3Factory} from "./03_DeployDCAV3Factory.s.sol";

import {AssetsWhitelist} from "../src/dependencies/AssetsWhitelist.sol";
import {DCAV3} from "../src/strategies/DcaV3.sol";
import {DCAV3Factory} from "../src/factories/DCAV3Factory.sol";

contract DeployAll is Script {
    function run() external {
        /* You can specify custom initial whitelist here or provide empty one and add assets later
            address[] memory core_assets_to_spend = new address[](0);
            address[] memory core_assets_to_buy = new address[](0);
            AssetsWhitelist whitelist = (new DeployAssetsWhitelist()).run(core_assets_to_spend, core_assets_to_buy);
      */
        console.log("Deploying whitelist");
        AssetsWhitelist whitelist = (new DeployAssetsWhitelist()).run();
        console.log("Whitelist deployed: ", address(whitelist));

        console.log("Deploying DCAV3 Implementation for later cloning");
        DCAV3 dcaImp = (new DeployDCAV3()).run();
        console.log("DCAV3 deployed: ", address(dcaImp));

        console.log("Deploying factory");
        DCAV3Factory factory = (new DeployDCAV3Factory()).run(address(whitelist), address(dcaImp));
        console.log("Factory deployed: ", address(factory));
    }
}
