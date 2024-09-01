// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, Ownable {
    //
    constructor(address _owner) ERC20("Recycle", "RCYCL") Ownable(_owner) {}

    function mintToken(address _to, uint256 _amount) external onlyOwner {
        _mint(_to, _amount);
    }

    function burnToken(address _from, uint256 _amount) external onlyOwner {
        _burn(_from, _amount);
    }
 
    function getBalance(address _user) external onlyOwner view returns(uint256)  {
        return balanceOf(_user);
    }
    //
}
