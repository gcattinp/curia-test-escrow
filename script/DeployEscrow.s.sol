// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {CuriaEscrow} from "../src/CuriaEscrow.sol";
import "forge-std/console.sol";

contract DeployEscrow is Script {
    function run() external returns (CuriaEscrow) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address account_deployer = vm.addr(privateKey);

        console.log("Deployer Account:", account_deployer);

        vm.startBroadcast(privateKey);
        CuriaEscrow curiaEscrow = new CuriaEscrow();
        vm.stopBroadcast();

        return curiaEscrow;
    }
}
