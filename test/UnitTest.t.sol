// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {EcoChain} from "../src/EcoChain.sol";
import {EcoChainDeploy} from "../script/EcoChainDeploy.s.sol";
import {Token} from "../src/Token.sol";

contract UnitTest is Test {
    //
    EcoChainDeploy ecoChainDeploy;
    EcoChain ecoChain;

    address private constant OWNER = address(1);
    address private constant ECOCHAIN_WASTE_BANK = address(2);
    address private constant BOB = address(3);
    address private constant ALICE = address(4);
    address private i_deployer;

    modifier registerWasteBank() {
        vm.startPrank(WASTE_BANK);
        ecoChain.registerWasteBank(
            "Indonesia",
            "Surabaya",
            "google-maps.com",
            1900,
            msg.sender
        );
        vm.stopPrank();

        uint256 expectedNumber = 1;
        uint256 actualNumber = ecoChain.getWasteBanks().length;
        assertEq(expectedNumber, actualNumber);
        _;
    }

    modifier createBobTransaction() {
        vm.startPrank(WASTE_BANK);
        ecoChain.createTransaction(BOB, 20, 0, 0);
        vm.stopPrank();

        uint256 expectedNumber = 1;
        uint256 actualNumber = ecoChain.getTransactions().length;
        assertEq(expectedNumber, actualNumber);
        _;
    }

    modifier createAliceTransaction() {
        vm.startPrank(WASTE_BANK);
        ecoChain.createTransaction(0, ALICE, 30, 0, 0);
        vm.stopPrank();
        _;
    }

    modifier approveTransaction() {
        vm.startPrank(BOB);
        ecoChain.approveTransaction(0);
        vm.stopPrank();

        uint256 expectedNumber = 200;
        uint256 actualNumber = Token(ecoChain.getTokenAddress()).getBalance(
            BOB
        );
        bool expectedValue = true;
        bool actualValue = ecoChain.getUserTransactions(BOB)[0].isApproved;
        assertEq(expectedNumber, actualNumber);
        assertEq(expectedValue, actualValue);
        _;
    }

    modifier approveBobTransaction() {
        vm.startPrank(BOB);
        ecoChain.approveTransaction(0);
        vm.stopPrank();
        _;
    }

    modifier approveAliceTransaction() {
        vm.startPrank(ALICE);
        ecoChain.approveTransaction(1);
        vm.stopPrank();
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

    modifier mintNewNFT() {
        vm.startPrank(i_deployer);
        ecoChain.mintNewNFT(
            "SAGE",
            "Lorem ipsum dolor sit amet",
            200,
            "ipfs://sage.com"
        );
        vm.stopPrank();

        uint256 expectedNumber = 1;
        uint256 actualNumber = ecoChain.getNFTArts().length;
        assertEq(expectedNumber, actualNumber);
        _;
    }

    modifier swapTokenWithNFT() {
        vm.startPrank(BOB);
        ecoChain.swapTokenWithNFT(0);
        vm.stopPrank();

        bool expectedValue = true;
        bool actualValue = ecoChain.getNFTArts()[0].isBought;
        assertEq(expectedValue, actualValue);
        _;
    }

    function setUp() public {
        ecoChainDeploy = new EcoChainDeploy();
        ecoChain = ecoChainDeploy.run();
        i_deployer = msg.sender;
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

    function testRevertIfInvalidReviewDataCalled() public registerWasteBank {
        vm.expectRevert(EcoChain.InvalidReviewData.selector);
        vm.startPrank(BOB);
        ecoChain.giveReview(0, "", 6);
        vm.stopPrank();
    }

    function testRevertIfNotNFTCreatorCalled() public {
        vm.expectRevert(EcoChain.NotNFTCreator.selector);
        vm.startPrank(BOB);
        ecoChain.mintNewNFT("SON", "LOREM IPSUM DOLOR", 50, "ipfs://son.com");
        vm.stopPrank();
    }

    function testRevertIfInvalidNFTArtDataCalled() public {
        vm.expectRevert(EcoChain.InvalidNFTArtData.selector);
        vm.startPrank(i_deployer);
        ecoChain.mintNewNFT("", "", 100, "");
        vm.stopPrank();
    }

    function testRevertIfNonExistingNFTArtCalled() public {
        vm.expectRevert(EcoChain.NonExistingNFTArt.selector);
        vm.startPrank(BOB);
        ecoChain.swapTokenWithNFT(1);
        vm.stopPrank();
    }

    function testRevertIfInsufficientUserBalanceCalled()
        public
        mintNewNFT
        registerWasteBank
        
        approveBobTransaction
    {
        vm.expectRevert(EcoChain.InsufficientBalance.selector);
        vm.startPrank(BOB);
        ecoChain.swapTokenWithNFT(0);
        vm.stopPrank();
    }

    function testRevertIfNFTAlreadyBoughtCalled()
        public
        mintNewNFT
        registerWasteBank
        createTransaction
        approveTransaction
        swapTokenWithNFT
        createAliceTransaction
        approveAliceTransaction
    {
        vm.expectRevert(abi.encodeWithSelector(EcoChain.NFTAlreadyBought.selector, 0));
        vm.startPrank(ALICE);
        ecoChain.swapTokenWithNFT(0);
        vm.stopPrank();
    }

    function testSuccessfullyGetTokenAddress() public view {
        assert(ecoChain.getTokenAddress() != address(0));
    }

    function testSuccessfullyGetNFTAddress() public view {
        assert(ecoChain.getNFTAddress() != address(0));
    }

    function testSuccessfullyGetNFTCreator() public view {
        assertEq(ecoChain.getNFTCreator(), i_deployer);
    }

    function testSuccessfullyApproveTransaction()
        public
        registerWasteBank
        createTransaction
        approveTransaction
    {}

    function testSuccessfullyGiveReview() public registerWasteBank giveReview {}

    function testSuccessfullyMintNewNFT() public mintNewNFT {}

    //
}
