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

    address private i_owner;
    address private constant ECOCHAIN_WASTE_BANK = address(2);
    address private constant BOB = address(3);
    address private constant ALICE = address(4);

    modifier registerWasteBank() {
        vm.startPrank(i_owner);
        ecoChain.registerWasteBank(
            "Indonesia",
            "Surabaya",
            "google-maps.com",
            ECOCHAIN_WASTE_BANK
        );
        vm.stopPrank();

        uint256 expectedNumber = 1;
        uint256 actualNumber = ecoChain.getWasteBanks().length;
        assertEq(expectedNumber, actualNumber);
        _;
    }

    modifier createBobTransaction() {
        vm.startPrank(ECOCHAIN_WASTE_BANK);
        ecoChain.createTransaction(BOB, 20, 0, 0);
        vm.stopPrank();

        uint256 expectedNumber = 1;
        uint256 actualNumber = ecoChain.getTransactions().length;
        assertEq(expectedNumber, actualNumber);
        _;
    }

    modifier createAliceTransaction() {
        vm.startPrank(ECOCHAIN_WASTE_BANK);
        ecoChain.createTransaction(ALICE, 20, 0, 0);
        vm.stopPrank();
        _;
    }

    modifier giveReview() {
        vm.startPrank(BOB);
        ecoChain.giveReview("Good!", 5);
        vm.stopPrank();

        uint256 expectedNumber = 1;
        uint256 actualNumber = ecoChain.getReviews().length;
        assertEq(expectedNumber, actualNumber);
        _;
    }

    modifier mintNewNFT() {
        vm.startPrank(i_owner);
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

    modifier addFAQ() {
        vm.startPrank(i_owner);
        ecoChain.addNewFAQ("What color is it", "Red");
        vm.stopPrank();

        uint256 expectedNumber = 1;
        uint256 actualNumber = ecoChain.getFAQs().length;
        assertEq(expectedNumber, actualNumber);
        _;
    }

    modifier swapBobTokenWithNFT() {
        vm.startPrank(BOB);
        ecoChain.swapTokenWithNFT(0);
        vm.stopPrank();
        _;
    }

    function setUp() public {
        ecoChainDeploy = new EcoChainDeploy();
        ecoChain = ecoChainDeploy.run();
        i_owner = ecoChain.getOwner();
    }

    function testRevertIfInvalidWasteBankDataCalled() public {
        vm.expectRevert(EcoChain.InvalidWasteBankData.selector);
        vm.startPrank(i_owner);
        ecoChain.registerWasteBank(
            "",
            "",
            "Lorem ipsum dolor sit amet",
            ECOCHAIN_WASTE_BANK
        );
        vm.stopPrank();
    }

    function testRevertIfInvalidFAQDataCalled() public {
        vm.expectRevert(EcoChain.InvalidFAQData.selector);
        vm.startPrank(i_owner);
        ecoChain.addNewFAQ("What color is it? ", "");
        vm.stopPrank();
    }

    function testRevertIfWalletAreadyRegisteredCalled()
        public
        registerWasteBank
    {
        vm.expectRevert(
            abi.encodeWithSelector(
                EcoChain.WalletAlreadyRegistered.selector,
                ECOCHAIN_WASTE_BANK
            )
        );
        vm.startPrank(i_owner);
        ecoChain.registerWasteBank(
            "Indonesia",
            "Jakarta",
            "googlemaps.com",
            ECOCHAIN_WASTE_BANK
        );
        vm.stopPrank();
    }

    function testRevertIfInvalidWasteBankWalletCalled()
        public
        registerWasteBank
    {
        vm.expectRevert(EcoChain.InvalidWasteBankWallet.selector);
        vm.startPrank(BOB);
        ecoChain.createTransaction(msg.sender, 0, 1, 1);
        vm.stopPrank();
    }

    function testRevertIfInvalidTransactionDataCalled()
        public
        registerWasteBank
    {
        vm.expectRevert(EcoChain.InvalidTransactionData.selector);
        vm.startPrank(ECOCHAIN_WASTE_BANK);
        ecoChain.createTransaction(BOB, 0, 0, 0);
        vm.stopPrank();
    }

    function testRevertIfInvalidReviewDataCalled() public registerWasteBank {
        vm.expectRevert(EcoChain.InvalidReviewData.selector);
        vm.startPrank(BOB);
        ecoChain.giveReview("", 6);
        vm.stopPrank();
    }

    function testRevertIfInvalidNFTArtDataCalled() public {
        vm.expectRevert(EcoChain.InvalidNFTArtData.selector);
        vm.startPrank(i_owner);
        ecoChain.mintNewNFT("", "", 100, "");
        vm.stopPrank();
    }

    function testRevertIfNonExistingNFTArtCalled() public {
        vm.expectRevert(EcoChain.NonExistingNFTArt.selector);
        vm.startPrank(BOB);
        ecoChain.swapTokenWithNFT(1);
        vm.stopPrank();
    }

    function testRevertIfNFTArtAlreadyBought()
        public
        mintNewNFT
        registerWasteBank
        createBobTransaction
        swapBobTokenWithNFT
        createAliceTransaction
    {
        vm.expectRevert(abi.encodeWithSelector(EcoChain.NFTArtAlreadyBought.selector, 0));
        vm.startPrank(ALICE);
        ecoChain.swapTokenWithNFT(0);
        vm.stopPrank();
    }

    function testRevertIfInsufficientUserBalanceCalled()
        public
        mintNewNFT
        registerWasteBank
    {
        vm.expectRevert(EcoChain.InsufficientBalance.selector);
        vm.startPrank(BOB);
        ecoChain.swapTokenWithNFT(0);
        vm.stopPrank();
    }

    function testSuccessfullyGetToken()
        public
        registerWasteBank
        createBobTransaction
    {
        uint256 expectedNumber = 200;
        uint256 actualNumber = ecoChain.getUserBalance(BOB);
        assertEq(expectedNumber, actualNumber);
    }

    function testSuccessfullyBurnTokenAfterSwap()
        public
        mintNewNFT
        registerWasteBank
        createBobTransaction
        swapBobTokenWithNFT
    {
        uint256 expectedNumber = 0;
        uint256 actualNumber = ecoChain.getUserBalance(BOB);
        assertEq(expectedNumber, actualNumber);
    }

    function testSuccessfullyGetTokenAddress() public view {
        assert(ecoChain.getTokenAddress() != address(0));
    }

    function testSuccessfullyGetNFTAddress() public view {
        assert(ecoChain.getNFTAddress() != address(0));
    }

    function testSuccessfullyGetOwner() public view {
        assert(ecoChain.getOwner() == i_owner);
    }

    function testSuccessfullyGiveReview() public registerWasteBank giveReview {}

    function testSuccessfullyMintNewNFT() public mintNewNFT {}

    //
}
