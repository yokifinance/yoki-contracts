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
        console.log("RPSV1 deployed: ", address(rpsImp));
        address[] memory admins = new address[](3);
        admins[0] = address(0x94Ad54EC1299B9BE82eCc9328187eF37fDB07329);
        admins[1] = address(0x2D9a8BE931f1EAb82ABFCb9697023424E440CD43);
        admins[2] = address(0xB0b12f40b18027f1a2074D2Ab11C6e0d6c6acbB5);

        console.log("Deploying RPSV1Factory");
        RPSV1Factory factory = new RPSV1Factory(address(rpsImp), admins);
        console.log("Factory deployed: ", address(factory));
        vm.stopBroadcast();
    }
}
