// SPDX-License-Identifier: MIT

pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20 {
    //
    constructor() ERC20("Recycle", "RCYCL") {}

    function mintToken(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function burnToken(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }

    function getBalance() external view returns(uint256) {
        return balanceOf(msg.sender);
    }
    //
}
