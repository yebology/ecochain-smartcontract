// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

contract EcoChain {
    //
    enum MemberType {
        SMALL,
        MEDIUM,
        LARGE
    }

    struct RecyclingCompany {
        uint256 id;
        string companyLogo;
        string companyName;
        string companyDescription;
        string companyAddress;
        uint16 companyFoundedYear;
        uint256 trashWeightRequirement;
        string companyWebsite;
    }

    struct RecylingCompanyRating {
        uint256 companyId;
        uint256 communityId;
        uint256 rating;
        uint256 timestamp;
        string feedback;
    }

    struct EcoCommunityRating {
        uint256 communityId;
        uint256 companyId;
        uint256 rating;
        uint256 timestamp;
        string feedback;
    }

    struct EcoCommunity {
        uint256 id;
        string communityLogo;
        string communityName;
        string communityDescription;
        string communityAddress;
        uint16 communityFoundedYear;
        MemberType communityMemberType;
        string communityWebsite;
    }

    RecyclingCompany[] private recyclingCompanyList;
    RecylingCompanyRating[] private recylingCompanyRating;

    EcoCommunity[] private ecoCommunityList;
    EcoCommunityRating[] private ecoCommunityRating;

    modifier onlyCompany {
        _;
    }

    modifier onlyCommunity {
        _;
    }

    function registerRecyclingCompany(
        string memory _logo,
        string memory _name,
        string memory _description,
        string memory _address,
        uint16 _foundedYear,
        uint256 _trashWeightRequirement,
        string memory _website
    ) external {
        recyclingCompanyList.push(
            RecyclingCompany({
                id: recyclingCompanyList.length,
                companyLogo: _logo,
                companyName: _name,
                companyDescription: _description,
                companyAddress: _address,
                companyFoundedYear: _foundedYear,
                trashWeightRequirement: _trashWeightRequirement,
                companyWebsite: _website
            })
        );
    }

    function registerEcoCommunity(
        string memory _image,
        string memory _name,
        string memory _description,
        string memory _address,
        uint16 _foundedYear,
        uint8 _memberCountState,
        string memory _website
    ) external {

    }

    function requestConnectionToCompany(uint256 _companyId) onlyCommunity() external {

    }

    function approveCommunityRequest(uint256 _communityId) onlyCompany() external {

    }

    function approveCompanyProcess() external onlyCommunity() {
        
    }

    function giveFeedbackToCompany() external onlyCommunity() {

    }

    function giveFeedbackToCommunity() external onlyCompany() {

    }

    function getEcoCommunity() external view returns (EcoCommunity[] memory) {
        return ecoCommunityList;
    }

    function getRecyclingCompany() external view returns (RecyclingCompany[] memory) {
        return recyclingCompanyList;
    }
    //
}