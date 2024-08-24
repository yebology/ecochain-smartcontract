// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Token is ERC20, Ownable, ReentrancyGuard  {
    // 
    constructor() ERC20("Recycle", "RCYCL") Ownable(msg.sender) {}

    function mintToken(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function getBalance(address _user) external view returns (uint256) {
        return balanceOf(_user);
    }

    function transferTo(address _to, uint256 _amount) external nonReentrant {
        transfer(_to, _amount);
    }
    //
}