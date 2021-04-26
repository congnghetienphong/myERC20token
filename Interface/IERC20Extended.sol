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
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);
    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
    
 }
