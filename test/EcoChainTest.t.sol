// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {EcoChain} from "../src/EcoChain.sol";
import {EcoChainDeploy} from "../script/EcoChainDeploy.s.sol";

contract EcoChainTest is Test {
    //
    EcoChainDeploy ecoChainDeploy;
    EcoChain ecoChain;

    address private constant WASTE_BANK = address(1);
    address private constant BOB = address(2);

    modifier registerWasteBank() {
        vm.startPrank(WASTE_BANK);
        ecoChain.registerWasteBank(
            "Logo.png",
            "Waste Bank",
            "Lorem ipsum dolor sit amet",
            "Surabaya, East Java, Indonesia",
            1900,
            "wastebank.co.id"
        );
        vm.stopPrank();

        uint256 expectedNumber = 1;
        uint256 actualNumber = ecoChain.getWasteBank().length;
        assertEq(expectedNumber, actualNumber);
        _;
    }

    modifier createTransaction() {
        vm.startPrank(WASTE_BANK);
        ecoChain.createTransaction(0, BOB, 0, 1, 0);
        vm.stopPrank();

        uint256 expectedNumber = 1;
        uint256 actualNumber = ecoChain.getTransactionsForUser(BOB).length;
        assertEq(expectedNumber, actualNumber);
        _;
    }

    function setUp() public {
        ecoChainDeploy = new EcoChainDeploy();
        ecoChain = ecoChainDeploy.run();
    }

    function testRevertIfInvalidWasteBankData() public {
        vm.expectRevert(EcoChain.InvalidWasteBankData.selector);
        vm.startPrank(WASTE_BANK);
        ecoChain.registerWasteBank(
            "",
            "",
            "Lorem ipsum dolor sit amet",
            "",
            0,
            ""
        );
        vm.stopPrank();
    }

    function testRevertIfInvalidWasteBankWallet() public registerWasteBank {
        vm.expectRevert(EcoChain.InvalidWasteBankWallet.selector);
        vm.startPrank(BOB);
        ecoChain.createTransaction(
            0,
            msg.sender,
            0,
            1,
            1
        );
        vm.stopPrank();
    }

    //
}
