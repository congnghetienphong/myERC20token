// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// A library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c>=a, 'ds-math-mul-overflow');
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a - b;
        require(c<=a, 'ds-math-sub-underflow');
        return c;
    }
    
    function mul(uint a, uint b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(b==0||c/b==a, 'ds-math-mul-overflow');
        return c;
    }
    
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'ds-math-div-overflow');
        uint256 c = a / b;
        return c;
    }
    
   /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'ds-math-mod-overflow');
        return a % b;
    }
    
    function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a < b? a : b;
    }
    
    // Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 s) internal pure returns (uint r) {
        r = 1; 
        uint256 h = s;
        while(r<h) {
            h = (h+s)/2;
            r = s/h;
        }
    }
}
