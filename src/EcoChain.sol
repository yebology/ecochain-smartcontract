// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {NFT} from "../src/NFT.sol";
import {Token} from "../src/Token.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EcoChain is ReentrancyGuard, Ownable {
    //
    struct WasteBank {
        uint256 id;
        string country;
        string city;
        string location;
        address wallet;
        uint16 postalCode;
        uint16 foundedYear;
    }
    struct Review {
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
        string image;
        uint256 price;
    }

    WasteBank[] private wasteBanks;
    Review[] private reviews;
    Transaction[] private transactions;
    NFTArt[] private nftArts;

    Token i_token;
    NFT i_nft;

    uint256 constant BOTTLE_PRICE_PER_KG = 10;
    uint256 constant PAPER_PRICE_PER_KG = 20;
    uint256 constant CAN_PRICE_PER_KG = 30;

    event WasteBankRegistered(
        string country,
        string city,
        string location,
        uint16 postalCode
    );
    event ReviewCreated(address indexed user);
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
    event NFTMinted(uint256 indexed tokenId);
    event NFTPurchased(uint256 indexed tokenId, address indexed user);

    error InvalidWasteBankWallet();
    error InvalidUser();
    error NonExistingNFTArt();
    error NonExistingWasteBank();
    error TransactionAlreadyApproved(uint256 transactionId);
    error NonExistingTransaction();
    error InsufficientBalance();
    error InvalidWasteBankData();
    error InvalidTransactionData();
    error InvalidReviewData();
    error InvalidNFTArtData();

    modifier requireExistingWasteBank(uint256 _wasteBankId) {
        if (wasteBanks.length < _wasteBankId) {
            revert NonExistingWasteBank();
        }
        _;
    }

    modifier requireExistingTransaction(uint256 _transactionId) {
        if (transactions.length < _transactionId) {
            revert NonExistingTransaction();
        }
        _;
    }

    modifier requireExistingNFTArt(uint256 _tokenId) {
        if (nftArts.length < _tokenId) {
            revert NonExistingNFTArt();
        }
        _;
    }

    modifier onlyWasteBank(address _wallet, uint256 _wasteBankId) {
        if (wasteBanks[_wasteBankId].wallet != _wallet) {
            revert InvalidWasteBankWallet();
        }
        _;
    }

    modifier onlyUser(uint256 _transactionId, address _user) {
        if (transactions[_transactionId].user != _user) {
            revert InvalidUser();
        }
        _;
    }

    modifier checkTransactionStatus(uint256 _transactionId) {
        if (transactions[_transactionId].isApproved == true) {
            revert TransactionAlreadyApproved(_transactionId);
        }
        _;
    }

    modifier checkUserBalance(uint256 _tokenId) {
        uint256 userBalance = i_token.getBalance(msg.sender);
        uint256 nftArtPrice = nftArts[_tokenId].price;
        if (userBalance < nftArtPrice) {
            revert InsufficientBalance();
        }
        _;
    }

    modifier validateWasteBankRegistration(
        string memory _country,
        string memory _city,
        string memory _location,
        uint16 _postalCode,
        uint16 _foundedYear,
        address _wallet
    ) {
        if (
            bytes(_country).length == 0 ||
            bytes(_city).length == 0 ||
            bytes(_location).length == 0 ||
            _postalCode == 0 ||
            _foundedYear == 0 ||
            _wallet != address(0)
        ) {
            revert InvalidWasteBankData();
        }
        _;
    }

    modifier validateTransaction(
        address _user,
        uint256 _bottleWeightInKg,
        uint256 _paperWeightInKg,
        uint256 _canWeightInKg
    ) {
        if (
            _user == address(0) ||
            (_bottleWeightInKg == 0 &&
                _paperWeightInKg == 0 &&
                _canWeightInKg == 0)
        ) {
            revert InvalidTransactionData();
        }
        _;
    }

    modifier validateReview(string memory _review, uint8 _rating) {
        if (bytes(_review).length == 0 || _rating < 1 || _rating > 5) {
            revert InvalidReviewData();
        }
        _;
    }

    modifier validateNFTArt(
        string memory _name,
        string memory _description,
        uint256 _price,
        string memory _calldata,
        string memory _image
    ) {
        if (
            bytes(_name).length == 0 ||
            bytes(_description).length == 0 ||
            _price == 0 ||
            bytes(_calldata).length == 0 ||
            bytes(_image).length == 0
        ) {
            revert InvalidNFTArtData();
        }
        _;
    }

    constructor(address _creator) Ownable(_creator) {
        i_token = new Token();
        i_nft = new NFT(_creator);
    }

    function registerWasteBank(
        string memory _country,
        string memory _city,
        string memory _location,
        uint16 _postalCode,
        uint16 _foundedYear,
        address _wallet
    )
        external
        onlyOwner
        validateWasteBankRegistration(
            _country,
            _city,
            _location,
            _postalCode,
            _foundedYear,
            _wallet
        )
    {
        wasteBanks.push(
            WasteBank({
                id: wasteBanks.length,
                wallet: _wallet,
                country: _country,
                city: _city,
                location: _location,
                postalCode: _postalCode,
                foundedYear: _foundedYear
            })
        );
        emit WasteBankRegistered(_country, _city, _location, _postalCode);
    }

    function createTransaction(
        uint256 _wasteBankId,
        address _user,
        uint256 _bottleWeightInKg,
        uint256 _paperWeightInKg,
        uint256 _canWeightInKg
    )
        external
        requireExistingWasteBank(_wasteBankId)
        onlyWasteBank(msg.sender, _wasteBankId)
        validateTransaction(
            _user,
            _bottleWeightInKg,
            _paperWeightInKg,
            _canWeightInKg
        )
    {
        uint256 totalValue = (_bottleWeightInKg * BOTTLE_PRICE_PER_KG) +
            (_paperWeightInKg * PAPER_PRICE_PER_KG) +
            (_canWeightInKg * CAN_PRICE_PER_KG);
        transactions.push(
            Transaction({
                id: transactions.length,
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
        transactions[_transactionId].isApproved = true;
        _sendTokenToUser(msg.sender, _transactionId);
        emit ApprovedTransaction(msg.sender, _transactionId);
    }

    function _sendTokenToUser(
        address _user,
        uint256 _transactionId
    ) private nonReentrant {
        uint256 tokenValue = transactions[_transactionId].tokenReceived;
        i_token.mintToken(_user, tokenValue);
    }

    function swapTokenWithNFT(
        uint256 _tokenId
    )
        external
        requireExistingNFTArt(_tokenId)
        checkUserBalance(_tokenId)
        nonReentrant
    {
        uint256 nftArtPrice = nftArts[_tokenId].price;
        address owner = owner();
        i_nft.transferNFT(owner, msg.sender, _tokenId);
        i_token.burnToken(msg.sender, nftArtPrice);
        emit NFTPurchased(_tokenId, msg.sender);
    }

    function giveReview(
        string memory _review,
        uint8 _rating
    )
        external
        validateReview(_review, _rating)
    {
        reviews.push(
            Review({
                reviewer: msg.sender,
                rating: _rating,
                timestamp: block.timestamp,
                review: _review
            })
        );
        emit ReviewCreated(msg.sender);
    }

    function mintNewNFT(
        string memory _name,
        string memory _description,
        uint256 _price,
        string memory _calldata,
        string memory _image
    )
        external
        onlyOwner
        validateNFTArt(_name, _description, _price, _calldata, _image)
    {
        uint256 tokenId = nftArts.length;
        address owner = owner();

        nftArts.push(
            NFTArt({
                id: tokenId,
                name: _name,
                description: _description,
                image: _image,
                price: _price
            })
        );
        i_nft.mintNFT(owner, tokenId, _calldata);
        emit NFTMinted(tokenId);
    }

    function getUserBalance(address _user) external view returns (uint256) {
        return i_token.getBalance(_user);
    }

    function getTokenAddress() external view returns (address) {
        return address(i_token);
    }

    function getNFTAddress() external view returns (address) {
        return address(i_nft);
    }

    function getNFTArts() external view returns (NFTArt[] memory) {
        return nftArts;
    }

    function getWasteBanks() external view returns (WasteBank[] memory) {
        return wasteBanks;
    }

    function getReviews() external view returns (Review[] memory) {
        return reviews;
    }

    function getUserTransactions(
        address _user
    ) external view returns (Transaction[] memory) {
        uint256 size = transactions.length;
        uint256 userTransactionTotal = _countUserTransactions(_user, size);
        Transaction[] memory userTransactions = new Transaction[](
            userTransactionTotal
        );
        uint256 index = 0;
        for (uint256 i = 0; i < size; i++) {
            if (transactions[i].user == _user) {
                userTransactions[index] = transactions[i];
                index++;
            }
        }
        return userTransactions;
    }

    function getWasteBankTransactions(
        uint256 _wasteBankId
    )
        external
        view
        requireExistingWasteBank(_wasteBankId)
        returns (Transaction[] memory)
    {
        uint256 size = transactions.length;
        uint256 wasteBankTransactionTotal = _countWasteBankTransactions(
            _wasteBankId,
            size
        );
        Transaction[] memory wasteBankTransactions = new Transaction[](
            wasteBankTransactionTotal
        );
        uint256 index = 0;
        for (uint256 i = 0; i < size; i++) {
            if (transactions[i].wasteBankId == _wasteBankId) {
                wasteBankTransactions[index] = transactions[i];
                index++;
            }
        }
        return wasteBankTransactions;
    }

    function _countWasteBankTransactions(
        uint256 _wasteBankId,
        uint256 _size
    ) private view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _size; i++) {
            if (transactions[i].wasteBankId == _wasteBankId) {
                total++;
            }
        }
        return total;
    }

    function _countUserTransactions(
        address _user,
        uint256 _size
    ) private view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _size; i++) {
            if (transactions[i].user == _user) {
                total++;
            }
        }
        return total;
    }
    //
}
