// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import { Test } from "forge-std/Test.sol";
import { EcoChain } from "../src/EcoChain.sol";
import { EcoChainDeploy } from "../script/EcoChainDeploy.s.sol";

contract EcoChainTest is Test {
    //
    EcoChainDeploy ecoChainDeploy;
    EcoChain ecoChain;

    function setUp() public {
        ecoChainDeploy = new EcoChainDeploy();
        ecoChain = ecoChainDeploy.run();
    }
    //
}