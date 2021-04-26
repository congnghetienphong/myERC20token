// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// A library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c=a+b)>=a, 'ds-math-mul-overflow');
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c=a-b)<=a, 'ds-math-sub-underflow');
    }
    
    function mul(uint a, uint b) internal pure returns (uint c) {
        require(b==0||(c=a*b)/b==a, 'ds-math-mul-overflow');
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
