// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721URIStorage, Ownable {
    //
    constructor() ERC721("Recycle", "RCYCL") Ownable(msg.sender) {}

    function mintNFT(
        address _to,
        uint256 _tokenId,
        string calldata _uri
    ) external onlyOwner() {
        _safeMint(_to, _tokenId);
        _setTokenURI(_tokenId, _uri);
    }

    function transferNFT(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        _safeTransfer(_from, _to, _tokenId);
    }
    //
}
