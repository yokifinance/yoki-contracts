// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {RPSV1} from "@RPS/RPSV1.sol";
import {RPSV1Factory} from "@RPS/RPSV1Factory.sol";

contract DeployAll is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        console.log("Deploying RPSV1 implementation for cloning");
        RPSV1 rpsImp = new RPSV1();
        console.log("RPSV1 impl address: ", address(rpsImp));

        uint256 adminCount = vm.envUint("admin_count");
        console.log("Setting admins.. ", adminCount, " specified");

        address[] memory admins = new address[](adminCount);
        for (uint256 i = 0; i < adminCount; i++) {
            string memory key = string(
                abi.encodePacked("admin_address", vm.toString(i))
            );

            admins[i] = vm.envAddress(key);
            console.log("Admin ", admins[i], " found");
        }

        console.log("Deploying RPSV1Factory");
        RPSV1Factory factory = new RPSV1Factory(address(rpsImp), admins);
        console.log("Factory deployed: ", address(factory));
        vm.stopBroadcast();
    }
}
