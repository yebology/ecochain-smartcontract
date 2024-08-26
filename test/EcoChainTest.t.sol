// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import { Test } from "forge-std/Test.sol";
import { EcoChain } from "../src/EcoChain.sol";
import { EcoChainDeploy } from "../script/EcoChainDeploy.s.sol";

contract EcoChainTest is Test {
    //
    EcoChainDeploy ecoChainDeploy;
    EcoChain ecoChain;

    modifier registerWasteBank() {
        ecoChain.registerWasteBank(
            "Logo.png",
            "Waste Bank",
            "Lorem ipsum dolor sit amet",
            "Surabaya, East Java, Indonesia",
            1900,
            "wastebank.co.id"
        );
        _;
    }

    function setUp() public {
        ecoChainDeploy = new EcoChainDeploy();
        ecoChain = ecoChainDeploy.run();
    }

    

    //
}