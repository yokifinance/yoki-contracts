// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";
import {DCAV3Factory} from "../src/factories/DCAV3Factory.sol";

contract DeployDCAV3Factory is Script {
    function run(address swapRouter_, address assetsWhitelist_, address dcav3Implementation_)
        public
        returns (DCAV3Factory)
    {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        DCAV3Factory dcav3Factory = new DCAV3Factory(swapRouter_, assetsWhitelist_, dcav3Implementation_);
        vm.stopBroadcast();
        return dcav3Factory;
    }

    function run() external returns (DCAV3Factory) {
        address assetsWhitelist = 0x725edF790C82812e8C113bc6cAb1a03e4Ef7EC1A;
        address dcav3Implementation = 0xb1340E58954513b432875C0939D795bB01e3b907;
        // 0x10ED43C718714eb63d5aA57B78B54704E256024E - BNB
        // 0xE592427A0AEce92De3Edee1F18E0157C05861564 - polygon/optimism
        address swapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        return run(swapRouter, assetsWhitelist, dcav3Implementation);
    }
}
