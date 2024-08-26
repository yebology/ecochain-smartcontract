// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {EcoChain} from "../src/EcoChain.sol";
import {EcoChainDeploy} from "../script/EcoChainDeploy.s.sol";

contract UnitTest is Test {
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
        uint256 actualNumber = ecoChain.getWasteBanks().length;
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

    modifier giveReview() {
        vm.startPrank(BOB);
        ecoChain.giveReview(0, "Good!", 5);
        vm.stopPrank();

        uint256 expectedNumber = 1;
        uint256 actualNumber = ecoChain.getReviews(0).length;
        assertEq(expectedNumber, actualNumber);
        _;
    }

    function setUp() public {
        ecoChainDeploy = new EcoChainDeploy();
        ecoChain = ecoChainDeploy.run();
    }

    function testRevertIfInvalidWasteBankDataCalled() public {
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

    function testRevertIfNonExistingWasteBankCalled() public {
        vm.expectRevert(EcoChain.NonExistingWasteBank.selector);
        vm.startPrank(WASTE_BANK);
        ecoChain.createTransaction(1, BOB, 0, 1, 1);
        vm.stopPrank();
    }

    function testRevertIfInvalidWasteBankWalletCalled()
        public
        registerWasteBank
    {
        vm.expectRevert(EcoChain.InvalidWasteBankWallet.selector);
        vm.startPrank(BOB);
        ecoChain.createTransaction(0, msg.sender, 0, 1, 1);
        vm.stopPrank();
    }

    function testRevertIfInvalidTransactionDataCalled()
        public
        registerWasteBank
    {
        vm.expectRevert(EcoChain.InvalidTransactionData.selector);
        vm.startPrank(WASTE_BANK);
        ecoChain.createTransaction(0, BOB, 0, 0, 0);
        vm.stopPrank();
    }

    function testRevertIfNonExistingTransactionCalled() public {
        vm.expectRevert(EcoChain.NonExistingTransaction.selector);
        vm.startPrank(BOB);
        ecoChain.approveTransaction(1);
        vm.stopPrank();
    }

    function testRevertIfInvalidUserCalled()
        public
        registerWasteBank
        createTransaction
    {
        console.log(ecoChain.getTransactionsForUser(BOB).length);
        vm.expectRevert(EcoChain.InvalidUser.selector);
        vm.startPrank(WASTE_BANK);
        ecoChain.approveTransaction(0);
        vm.stopPrank();
    }

    function testRevertIfTransactionAlreadyApprovedCalled()
        public
        registerWasteBank
        createTransaction
    {
        vm.startPrank(BOB);
        ecoChain.approveTransaction(0);
        vm.expectRevert(
            abi.encodeWithSelector(
                EcoChain.TransactionAlreadyApproved.selector,
                0
            )
        );
        ecoChain.approveTransaction(0);
        vm.stopPrank();
    }

    function testRevertIfInvalidReviewDataCalled() public registerWasteBank() {
        vm.expectRevert(EcoChain.InvalidReviewData.selector);
        vm.startPrank(BOB);
        ecoChain.giveReview(0, "", 6);
        vm.stopPrank();
    }

    //
}
