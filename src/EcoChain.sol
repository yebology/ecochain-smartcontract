// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {NFT} from "../src/NFT.sol";
import {Token} from "../src/Token.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract EcoChain is ReentrancyGuard {
    //
    struct WasteBank {
        uint256 id;
        address wallet;
        string logo;
        string name;
        string description;
        string location;
        uint16 foundedYear;
        string website;
    }
    struct Review {
        uint256 wasteBankId;
        address reviewer;
        uint256 rating;
        uint256 timestamp;
        string review;
    }
    struct Transaction {
        uint256 id;
        uint256 wasteBankId;
        address user;
        uint256 tokenReceived;
        uint256 bottleWeightInKg;
        uint256 paperWeightInKg;
        uint256 canWeightInKg;
        uint256 timestamp;
        bool isApproved;
    }
    struct NFTArt {
        uint256 id;
        string name;
        string description;
        uint256 price;
        bool isBought;
    }

    WasteBank[] private wasteBankList;
    Review[] private reviewList;
    Transaction[] private transactionList;
    NFTArt[] private nftArtList;

    Token token;
    NFT nft;
    address nftCreator;

    uint256 constant BOTTLE_PRICE_PER_KG = 10;
    uint256 constant PAPER_PRICE_PER_KG = 20;
    uint256 constant CAN_PRICE_PER_KG = 30;

    event WasteBankRegistered(address indexed creator, string indexed name);
    event ReviewCreated(address indexed user, uint256 indexed wasteBankId);
    event TransactionCreated(uint256 indexed wasteBankId, address indexed user);
    event ApprovedTransaction(
        address indexed user,
        uint256 indexed transactionId
    );
    event WasteBankNFTCreated(
        uint256 indexed wasteBankId,
        address indexed nftAddress
    );
    event WasteBankNFTMinted(
        uint256 indexed wasteBankId,
        uint256 indexed tokenId
    );
    event NewNFTMinted(uint256 indexed tokenId);

    error InvalidWasteBankWallet();
    error InvalidUser();
    error NFTArtNotInitialized();
    error TransactionAlreadyApproved();
    error NonExistingTransaction();
    error NotNFTCreator();
    error InsufficientBalance();

    modifier requireExistingTransaction(uint256 _transactionId) {
        if (transactionList.length < _transactionId) {
            revert NonExistingTransaction();
        }
        _;
    }

    modifier requireNFTAlreadyInitialized(uint256 _tokenId) {
        if (nftArtList.length == 0) {
            revert NFTArtNotInitialized();
        }

        // if (nftArtList[_tokenId] == null) {
        //     revert NFTArtNotInitialized();
        // }
        _;
    }

    modifier onlyWasteBank(address _wallet, uint256 _wasteBankId) {
        if (wasteBankList[_wasteBankId].wallet != _wallet) {
            revert InvalidWasteBankWallet();
        }
        _;
    }

    modifier onlyUser(uint256 _transactionId, address _user) {
        if (transactionList[_transactionId].user != _user) {
            revert InvalidUser();
        }
        _;
    }

    modifier onlyNFTCreator() {
        if (msg.sender != nftCreator) {
            revert NotNFTCreator();
        }
        _;
    }

    modifier checkTransactionStatus(uint256 _transactionId) {
        if (transactionList[_transactionId].isApproved == true) {
            revert TransactionAlreadyApproved();
        }
        _;
    }

    modifier checkUserBalance(uint256 _tokenId) {
        uint256 userBalance = token.getBalance();
        uint256 nftArtPrice = nftArtList[_tokenId].price;
        if (userBalance < nftArtPrice) {
            revert InsufficientBalance();
        }
        _;
    }

    constructor() {
        token = new Token();
        nft = new NFT();
        nftCreator = msg.sender;
    }

    function registerWasteBank(
        string memory _logo,
        string memory _name,
        string memory _description,
        string memory _location,
        uint16 _foundedYear,
        string memory _website
    ) external {
        wasteBankList.push(
            WasteBank({
                id: wasteBankList.length,
                wallet: msg.sender,
                logo: _logo,
                name: _name,
                description: _description,
                location: _location,
                foundedYear: _foundedYear,
                website: _website
            })
        );
        emit WasteBankRegistered(msg.sender, _name);
    }

    function createTransaction(
        uint256 _wasteBankId,
        address _user,
        uint256 _bottleWeightInKg,
        uint256 _paperWeightInKg,
        uint256 _canWeightInKg
    ) external onlyWasteBank(msg.sender, _wasteBankId) {
        uint256 totalValue = (_bottleWeightInKg * BOTTLE_PRICE_PER_KG) +
            (_paperWeightInKg * PAPER_PRICE_PER_KG) +
            (_canWeightInKg * CAN_PRICE_PER_KG);
        transactionList.push(
            Transaction({
                id: transactionList.length,
                wasteBankId: _wasteBankId,
                user: _user,
                tokenReceived: totalValue,
                bottleWeightInKg: _bottleWeightInKg,
                paperWeightInKg: _paperWeightInKg,
                canWeightInKg: _canWeightInKg,
                timestamp: block.timestamp,
                isApproved: false
            })
        );
        emit TransactionCreated(_wasteBankId, _user);
    }

    function approveTransaction(
        uint256 _transactionId
    )
        external
        requireExistingTransaction(_transactionId)
        onlyUser(_transactionId, msg.sender)
        checkTransactionStatus(_transactionId)
    {
        transactionList[_transactionId].isApproved = true;
        _sendTokenToUser(_transactionId);
        emit ApprovedTransaction(msg.sender, _transactionId);
    }

    function _sendTokenToUser(uint256 _transactionId) private nonReentrant() {
        uint256 tokenValue = transactionList[_transactionId].tokenReceived;
        token.mintToken(msg.sender, tokenValue);
    }

    function swapTokenWithNFT(
        uint256 _tokenId
    ) external checkUserBalance(_tokenId) nonReentrant() {
        uint256 nftArtPrice = nftArtList[_tokenId].price;
        nft.transferNFT(nftCreator, msg.sender, _tokenId);
        token.burnToken(msg.sender, nftArtPrice);
    }

    function giveReview(
        uint256 _wasteBankId,
        string memory _review,
        uint8 _rating
    ) external {
        reviewList.push(
            Review({
                wasteBankId: _wasteBankId,
                reviewer: msg.sender,
                rating: _rating,
                timestamp: block.timestamp,
                review: _review
            })
        );
        emit ReviewCreated(msg.sender, _wasteBankId);
    }

    function mintNewNFT(
        string memory _name,
        string memory _description,
        uint256 _price,
        string memory _calldata
    ) external onlyNFTCreator() nonReentrant() {
        uint256 tokenId = nftArtList.length;
        nftArtList.push(
            NFTArt({
                id: tokenId,
                name: _name,
                description: _description,
                price: _price,
                isBought: false
            })
        );
        nft.mintNFT(nftCreator, tokenId, _calldata);
        emit NewNFTMinted(tokenId);
    }

    function getWasteBank() external view returns (WasteBank[] memory) {
        return wasteBankList;
    }

    function getReview() external view returns (Review[] memory) {
        return reviewList;
    }

    function getTransactionForUser(
        address _user
    ) external view returns (Transaction[] memory) {
        uint256 transactionLength = transactionList.length;
        uint256 index = 0;
        uint256 userTransactionTotal = _countUserTransaction(
            _user,
            transactionLength
        );
        Transaction[] memory transactions = new Transaction[](
            userTransactionTotal
        );
        for (uint256 i = 0; i < transactionLength; i++) {
            if (transactions[i].user == _user) {
                transactions[index] = transactionList[i];
                index++;
            }
        }
        return transactions;
    }

    function getTransactionForWasteBank(
        uint256 _wasteBankId
    ) external view returns (Transaction[] memory) {
        uint256 transactionLength = transactionList.length;
        uint256 index = 0;
        uint256 wasteBankTransactionTotal = _countWasteBankTransaction(
            _wasteBankId,
            transactionLength
        );
        Transaction[] memory transactions = new Transaction[](
            wasteBankTransactionTotal
        );
        for (uint256 i = 0; i < transactionLength; i++) {
            if (transactionList[i].wasteBankId == _wasteBankId) {
                transactions[index] = transactionList[i];
                index++;
            }
        }
        return transactions;
    }

    function _countWasteBankTransaction(
        uint256 _wasteBankId,
        uint256 _size
    ) private view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _size; i++) {
            if (transactionList[i].wasteBankId == _wasteBankId) {
                total++;
            }
        }
        return total;
    }

    function _countUserTransaction(
        address _user,
        uint256 _size
    ) private view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _size; i++) {
            if (transactionList[i].user == _user) {
                total++;
            }
        }
        return total;
    }
    //
}
