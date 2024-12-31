// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "../src/DugiTokenV2.sol";

contract DeployDugiToken is Script {
    function run() external {
        address charityWalletAddress = 0xf22C489A01dec560A1dB0414869B301C2D381229;
        address tokenBurnAdmin = 0x550675DC5307A4e5EE3C6FE63850c5187f52263D;

        uint256 pvtKey = vm.envUint("DEPLOYER_PVT_KEY");
        address account = vm.addr(pvtKey);
        console.log("deployer address on amoy = ", account);

        vm.startBroadcast(pvtKey);

        DUGITokenV2 dugiToken = new DUGITokenV2(charityWalletAddress, tokenBurnAdmin);

        vm.stopBroadcast();
    }
}
