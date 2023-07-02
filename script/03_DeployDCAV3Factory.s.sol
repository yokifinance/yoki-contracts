// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {DCAV3Factory} from "../src/factories/DCAV3Factory.sol";

contract DeployDCAV3Factory is Script {
    function run() external returns (DCAV3Factory) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address assetsWhitelist = 0x55767e19Dd3Aa623a4A2537cA2DE29bA95E740f7;
        address dcav3Implementation = 0x55767e19Dd3Aa623a4A2537cA2DE29bA95E740f7;
        vm.startBroadcast(deployerPrivateKey);
        DCAV3Factory dcav3Factory = new DCAV3Factory(assetsWhitelist, dcav3Implementation);
        vm.stopBroadcast();
        return dcav3Factory;
    }
}
