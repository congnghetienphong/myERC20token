// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.7.0 <0.9.0;

import "./_IERC20.sol";

/**
 * @dev Interface for the optional extended functions from the ERC20 standard.
 */
 
interface IERC20Extended is IERC20 {
    /**
    * @dev Interface for the optional extended functions from the ERC20 standard.
    * 
    * Returns the name of the token.
    */
    function name() external view returns (string memory);
    // Returns the symbol of the token.
    function symbol() external view returns (string memory);
    // Returns the decimals places of the token.
    function decimals() external view returns (uint8);
    
 }
