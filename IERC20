// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    // Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);
    //Returns the amount of tokens owned by an address.
    function balanceOf(address account) external view returns (uint256);
    /**
    * @dev The ERC-20 standard allow an owner to permit a spender
    * to be able to spend a certain number of tokens from the owner
    * 
    * Returns the remainning amount the spender will
    * be allowed to spend fron the owner
    */
    function allowance(address owner, address spender) external view returns (uint256);
    /** 
     * Moves the amount of tokens from the caller (msg.sender) to the recipient.
     * Emits a {Transfer} event.
     * Returns true is the operation succeed.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
    /**
    * Set the amount of the allowance the spender 
    * is permitted to transfer from the caller.
    * Emits an {Approve} event.
    * Returns a boolean value indicate whether
    * the alloance was seccessfully set.
    */
    function approve(address spender, uint256 amount) external returns (bool);
    /**
    * Moves the amount of tokens from sender to recipient
    * using the allowance mechanism, amount is then deducted
    * from the caller’s allowance
    * Emits a {Transfer} event.
    */
    function transferFrom(address sender,address recipient, uint amount) external returns (bool);
    /**
    * Emitted when the amount of tokens(VALUE) is sent
    * from the FROM to the TO. VALUE may be zero
    * In minting, FROM is 0x00..0000 which be the address
    * of TO in burnning.
    */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /**
    * Emitted when the amount of tokens is approved
    * by the OWNER to be used by the SPENDER.
    */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
