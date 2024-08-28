// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {NFT} from "../src/NFT.sol";
import {Token} from "../src/Token.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EcoChain is ReentrancyGuard, Ownable {
    //
    struct WasteBank {
        address wallet;
        string country;
        string city;
        string linkToMap;
    }
    struct Review {
        address reviewer;
        uint256 rating;
        uint256 timestamp;
        string review;
    }
    struct Transaction {
        address wasteBankWallet;
        address user;
        uint256 bottleWeightInKg;
        uint256 paperWeightInKg;
        uint256 canWeightInKg;
        uint256 timestamp;
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

    event WasteBankRegistered(string linkToMap);
    event ReviewCreated(address indexed user);
    event TransactionCreated(
        address indexed wasteBankWallet,
        address indexed user
    );
    event NFTMinted(uint256 indexed tokenId);
    event NFTPurchased(uint256 indexed tokenId, address indexed user);

    error NonExistingNFTArt();
    error InsufficientBalance();
    error WalletAlreadyRegistered();
    error InvalidUser();
    error InvalidWasteBankWallet();
    error InvalidWasteBankData();
    error InvalidTransactionData();
    error InvalidReviewData();
    error InvalidNFTArtData();

    modifier requireExistingNFTArt(uint256 _tokenId) {
        if (nftArts.length < _tokenId) {
            revert NonExistingNFTArt();
        }
        _;
    }

    modifier onlyWasteBank(address _wallet) {
        uint256 size = wasteBanks.length;
        bool isValid = false;
        for (uint256 i = 0; i < size; i++) {
            if (wasteBanks[i].wallet == _wallet) {
                isValid = true;
                break;
            }
        }
        if (!isValid) {
            revert InvalidWasteBankWallet();
        }
        _;
    }

    modifier checkWalletStatus(address _wallet) {
        uint256 size = wasteBanks.length;
        bool isRegistered = false;
        for (uint256 i = 0; i < size; i++) {
            if (wasteBanks[i].wallet == _wallet) {
                isRegistered = true;
                break;
            }
        }
        if (isRegistered) {
            revert WalletAlreadyRegistered();
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
        string memory _linkToMap,
        address _wallet
    ) {
        if (
            bytes(_country).length == 0 ||
            bytes(_city).length == 0 ||
            bytes(_linkToMap).length == 0 ||
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
        string memory _linkToMap,
        address _wallet
    )
        external
        onlyOwner
        validateWasteBankRegistration(_country, _city, _linkToMap, _wallet)
        checkWalletStatus(_wallet)
    {
        _addToWasteBanks(_wallet, _country, _city, _linkToMap);
        emit WasteBankRegistered(_linkToMap);
    }

    function createTransaction(
        address _user,
        uint256 _bottleWeightInKg,
        uint256 _paperWeightInKg,
        uint256 _canWeightInKg
    )
        external
        onlyWasteBank(msg.sender)
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
        _addToTransactions(
            msg.sender,
            _user,
            _bottleWeightInKg,
            _paperWeightInKg,
            _canWeightInKg
        );
        _sendTokenToUser(_user, totalValue);
        emit TransactionCreated(msg.sender, _user);
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
    ) external validateReview(_review, _rating) {
        _addToReviews(_review, _rating);
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
        _addToNftArts(tokenId, _name, _description, _price, _image);
        i_nft.mintNFT(owner, tokenId, _calldata);
        emit NFTMinted(tokenId);
    }

    function getUserBalance(address _user) external view returns (uint256) {
        return i_token.getBalance(_user);
    }

    function getOwner() external view returns (address) {
        return owner();
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

    function getTransactions() external view returns (Transaction[] memory) {
        return transactions;
    }

    function _addToWasteBanks(
        address _wallet,
        string memory _country,
        string memory _city,
        string memory _linkToMap
    ) private {
        wasteBanks.push(
            WasteBank({
                wallet: _wallet,
                country: _country,
                city: _city,
                linkToMap: _linkToMap
            })
        );
    }

    function _addToTransactions(
        address _wasteBankWallet,
        address _user,
        uint256 _bottleWeightInKg,
        uint256 _paperWeightInKg,
        uint256 _canWeightInKg
    ) private {
        transactions.push(
            Transaction({
                wasteBankWallet: _wasteBankWallet,
                user: _user,
                bottleWeightInKg: _bottleWeightInKg,
                paperWeightInKg: _paperWeightInKg,
                canWeightInKg: _canWeightInKg,
                timestamp: block.timestamp
            })
        );
    }

    function _addToReviews(string memory _review, uint256 _rating) private {
        reviews.push(
            Review({
                reviewer: msg.sender,
                rating: _rating,
                timestamp: block.timestamp,
                review: _review
            })
        );
    }

    function _addToNftArts(
        uint256 _tokenId,
        string memory _name,
        string memory _description,
        uint256 _price,
        string memory _image
    ) private {
        nftArts.push(
            NFTArt({
                id: _tokenId,
                name: _name,
                description: _description,
                image: _image,
                price: _price
            })
        );
    }

    function _sendTokenToUser(
        address _user,
        uint256 _amount
    ) private nonReentrant {
        i_token.mintToken(_user, _amount);
    }
    //
}
