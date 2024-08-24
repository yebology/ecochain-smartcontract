// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import { NFT } from "../src/NFT.sol";
import { Token } from "../src/Token.sol";

contract EcoChain {
    //
    struct Company {
        uint256 id;
        address owner;
        string logo;
        string name;
        string description;
        string location;
        uint16 foundedYear;
        string website;
    }
    struct CompanyReview {
        uint256 companyId;
        address reviewer;
        uint256 rating;
        uint256 timestamp;
        string review;
    }
    struct Transaction {
        uint256 id;
        uint256 companyId;
        address user;
        uint256 rcyclReceived;
        uint256 bottleWeightInKg;
        uint256 paperWeightInKg;
        uint256 canWeightInKg;
        uint256 timestamp;
        bool isApproved;
    }

    Company[] private companyList;
    CompanyReview[] private companyReviewList;
    Transaction[] private transactionList;

    uint256 constant BOTTLE_PRICE_PER_KG = 10;
    uint256 constant PAPER_PRICE_PER_KG = 20;
    uint256 constant CAN_PRICE_PER_KG = 30;

    mapping(uint256 companyId => address nftAssets) private nftAssetsByCompany;

    event CompanyRegistered(address indexed creator, string indexed name);
    event ReviewCreated(address indexed user, uint256 indexed companyId);
    event TransactionCreated(
        uint256 indexed companyId,
        address indexed user
    );
    event ApprovedTransaction(
        address indexed user,
        uint256 indexed transactionId
    );
    event CompanyNFTCreated(uint256 indexed companyId, address indexed nftAddress);
    event CompanyNFTMinted(uint256 indexed companyId, uint256 indexed tokenId);

    error InvalidCompanyOwner();
    error InvalidUser();
    error CompanyAlreadyHasNFT();

    modifier checkCompanyNFT(uint256 _companyId) {
        if (nftAssetsByCompany[_companyId] != address(0)) {
            revert CompanyAlreadyHasNFT();
        }
        _;
    }

    modifier onlyCompany(address _user, uint256 _companyId) {
        if (companyList[_companyId].owner != _user) {
            revert InvalidCompanyOwner();
        }
        _;
    }

    modifier onlyUser(uint256 _transactionId, address _user) {
        if (transactionList[_transactionId].user != _user) {
            revert InvalidUser();
        }
        _;
    }

    function registerRecyclingCompany(
        string memory _logo,
        string memory _name,
        string memory _description,
        string memory _location,
        uint16 _foundedYear,
        string memory _website
    ) external {
        companyList.push(
            Company({
                id: companyList.length,
                owner: msg.sender,
                logo: _logo,
                name: _name,
                description: _description,
                location: _location,
                foundedYear: _foundedYear,
                website: _website
            })
        );
        emit CompanyRegistered(msg.sender, _name);
    }

    function createTransaction(
        uint256 _companyId,
        address _user,
        uint256 _bottleWeightInKg,
        uint256 _paperWeightInKg,
        uint256 _canWeightInKg
    ) external onlyCompany(msg.sender, _companyId) {
        uint256 totalValue = (_bottleWeightInKg * BOTTLE_PRICE_PER_KG) +
            (_paperWeightInKg * PAPER_PRICE_PER_KG) +
            (_canWeightInKg * CAN_PRICE_PER_KG);
        transactionList.push(
            Transaction({
                id: transactionList.length,
                companyId: _companyId,
                user: _user,
                rcyclReceived: totalValue,
                bottleWeightInKg: _bottleWeightInKg,
                paperWeightInKg: _paperWeightInKg,
                canWeightInKg: _canWeightInKg,
                timestamp: block.timestamp,
                isApproved: false
            })
        );
        emit TransactionCreated(_companyId, _user);
    }

    function createCompanyNFT(
        uint256 _companyId,
        string memory _nftName,
        string memory _nftSymbol
    ) external onlyCompany(msg.sender, _companyId) checkCompanyNFT(_companyId) {
        NFT nft = new NFT(_nftName, _nftSymbol);
        nftAssetsByCompany[_companyId] = address(nft);
        emit CompanyNFTCreated(_companyId, address(nft));
    }

    function addCompanyNFT(
        uint256 _companyId,
        uint256 _tokenId,
        string memory _uri
    ) external onlyCompany(msg.sender, _companyId) {
        address companyNFT = nftAssetsByCompany[_companyId];
        NFT(companyNFT).mintNFT(msg.sender, _tokenId, _uri);
        emit CompanyNFTMinted(_companyId, _tokenId);
    }

    function approveTransaction(
        uint256 _transactionId
    ) external onlyUser(_transactionId, msg.sender) {
        transactionList[_transactionId].isApproved = true;
        emit ApprovedTransaction(msg.sender, _transactionId);
    }

    function giveReviewToCompany(
        uint256 _companyId,
        string memory _review,
        uint8 _rating
    ) external {
        companyReviewList.push(
            CompanyReview({
                companyId: _companyId,
                reviewer: msg.sender,
                rating: _rating,
                timestamp: block.timestamp,
                review: _review
            })
        );
        emit ReviewCreated(msg.sender, _companyId);
    }

    function getCompany() external view returns (Company[] memory) {
        return companyList;
    }

    function getCompanyReview() external view returns (CompanyReview[] memory) {
        return companyReviewList;
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

    function getTransactionForCompany(
        uint256 _companyId
    ) external view returns (Transaction[] memory) {
        uint256 transactionLength = transactionList.length;
        uint256 index = 0;
        uint256 companyTransactionTotal = _countCompanyTransaction(
            _companyId,
            transactionLength
        );
        Transaction[] memory transactions = new Transaction[](
            companyTransactionTotal
        );
        for (uint256 i = 0; i < transactionLength; i++) {
            if (transactionList[i].companyId == _companyId) {
                transactions[index] = transactionList[i];
                index++;
            }
        }
        return transactions;
    }

    function _countCompanyTransaction(
        uint256 _companyId,
        uint256 _size
    ) private view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _size; i++) {
            if (transactionList[i].companyId == _companyId) {
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
