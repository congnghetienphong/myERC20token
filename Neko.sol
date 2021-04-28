 // SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./_IERC20.sol";
import "./_SafeMath.sol";
import "./_IERC20Extended.sol";
import "./_Context.sol";

contract Neko is Context, IERC20, IERC20Extended {
    using SafeMath for uint256;
    string private constant name = 'Nekocoin';
    string private constant symbol= 'NEKO';
    uint8 private constant decimals = 18;
    uint256 totalSupply = 100000000000000; // 100 trillion of Nekocoins issued in Genesis
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowance;
    
    // event Approval(address indexed tokenOwner, address indexed permittedSpender, uint256 tokenValue);
    // event Transfer(address indexed From, address indexed To, uint256 tokenValue);

    constructor() public {
        balances[msg.sender] = total_supply;
    }
    
    /** @dev Creates `amount` tokens and assigns them to 
     * `account`, increasing the total supply.
     * 
     * Emits a {Transfer} event with `from` set to the zero address.
     */
     function mint(address account, uint256 amount) internal {
         require(account!=address(0), "ERC20: mint to the zero address");
         totalSupply = totalSupply.add(amount);
         balances[account] = balances[account].add(amount);
         emit Transfer(address(0), account, amount);
     }
     
    /**
     * @dev Destroys `amount` tokens from
     * `account`, reducing the total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
     function burn(address account, uint256 amount) internal {
         require(account!=address(0), "ERC20: burn from the zero address");
         require(amount<=balances[account], "ERC20: Insufficient balance to be burnt");
         balance[account] = balance[account].sub(amount);
         totalSupply = totalSupply.sub(amount);
     }
     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender!=address(0), "ERC20: transfer from the zero address");
        require(recipient!=address(0), "ERC20: transfer to the zero address");
        require(amount <= balances[sender], "ERC20: transfer amount exceeds balance");
        balances[sender] = balances[sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner!=address(0), "ERC20: approve from the zero address");
        require(spender!=address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function getName() public override view virtual returns (string memory) {
        return name;
    }
    
    function getSymbol() public override view virtual returns (string memory) {
        return symbol;
    }
    
    function getDecimals() public override view virtual returns (uint8) {
        return 18;
    }
    
    function getTotalSupply() public override view returns (uint256) {
        return totalSupply;
    }
    
    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }
    
    function allowance(address owner, address spender) public override view returns (uint256) {
        return allowances[owner][spender];
    }
    
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * 
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     * 
     * Emits an {Approval} event indicating the updated allowance.
     */
    function increaseAllowance(address spender, uint256 addedVal) external returns (bool) {
         allowances[msg.sender][spender] = allowances[msg.sender][spender].add(addedVal);
         return true;
     }
     
    function decreaseAllowance(address spender, uint256 subtractedVal) external returns (bool) {
         require(amount<=allowance[msg.sender][spender], "ERC20: Insufficient allowance to be subtracted");
         allowance[msg.sender][spender] = allowances[msg.sender][spender].sub(subtractedVal);
         return true;
     }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        // Caller is approved to spend more than "amount" tokens belongs to the sender.
        require(amount <= allowances[sender][msg.sender]);
        _transfer(sender, recipient, amount);
        allowances[sender][msg.sender] = allowances[sender][msg.sender].sub(amount);
        return true;
    }
 }
