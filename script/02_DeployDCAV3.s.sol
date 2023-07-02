// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {DCAV3} from "../src/strategies/DCAV3.sol";

contract DeployDCAV3 is Script {
    function run() external returns (DCAV3) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DCAV3 dcav3 = new DCAV3();
        vm.stopBroadcast();
        return dcav3;
    }
}
