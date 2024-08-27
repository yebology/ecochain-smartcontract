// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {EcoChain} from "../src/EcoChain.sol";

contract EcoChainDeploy is Script {
    //
    event EcoChainCreated(address indexed echoChain);

    function run() external returns (EcoChain) {
        vm.startBroadcast();
        EcoChain ecoChain = new EcoChain(msg.sender);
        vm.stopBroadcast();

        emit EcoChainCreated(address(ecoChain));
        return ecoChain;
    }
    //
}
