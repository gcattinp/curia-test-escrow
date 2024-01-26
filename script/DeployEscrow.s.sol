// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {CuriaFactory} from "../src/CuriaFactory.sol"; // Corrected this line
import "forge-std/console.sol";

contract DeployEscrowFactory is Script {
    function run() external returns (CuriaFactory) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address account_deployer = vm.addr(privateKey);

        console.log("Deployer Account:", account_deployer);

        vm.startBroadcast(privateKey);
        CuriaFactory curiaFactory = new CuriaFactory();
        vm.stopBroadcast();

        return curiaFactory;
    }
}
