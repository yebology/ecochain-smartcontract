// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

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

    event NewCompanyCreated();
    event NewReviewCreated();

    Company[] private companyList;
    CompanyReview[] private companyReviewList;

    modifier onlyCompany(address _user, uint256 _companyId) {
        uint256 companyLength = companyList.length;
        if (companyList[_companyId].owner == _user) {

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

    }

    function requestTransactionToCompany(uint256 _companyId) external {

    }

    function approveUserRequest(address _user, uint256 _companyId) onlyCompany(msg.sender, _companyId) external {

    }

    function giveReviewToCompany(uint256 _companyId, string memory _review, uint8 _rating) external {
        companyReviewList.push(
            CompanyReview({
                companyId: _companyId,
                reviewer: msg.sender,
                rating: _rating,
                timestamp: block.timestamp,
                review: _review
            })
        );
    }

    function getRecyclingCompany() external view returns (Company[] memory) {
        return companyList;
    }
    //
}