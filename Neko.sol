// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./IERC20.sol";
import "./SafeMath.sol";
import "./IERC20Extended.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract Neko is Context, IERC20, IERC20Extended, Ownable {
    using SafeMath for uint256;
    using Address for address;
    string private constant name = 'Neko';
    string private constant symbol= 'NEKO';
    uint8 private constant decimals = 18;
    
    uint256 private constant MAX = ~uint256(0); // 100 trillion of Nekocoins issued in Genesis
    uint256 private totalSupply = 10**15;
    uint256 private totalReflection = MAX - MAX%totalSupply;
    uint256 private totalFees;
    
    uint256 public taxFee = 5;
    uint256 private previousTaxFee = taxFee;
    uint256 public liquidityFee = 5;
    uint256 private previousLiqFee = liquidityFee;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public maxTxAmount = totalSupply.div(2);
    uint256 private tokensSoldToAddLiq = totalSupply.div(2);

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    mapping(address => uint256) private refOwned;
    mapping(address => uint256) private tokensOwned;
    
    address[] private excluded;
    mapping(address => bool) private isExcludedFromFee;
    mapping(address => bool) private isExcluded;
    
    event minTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    // event Approval(address indexed tokenOwner, address indexed permittedSpender, uint256 tokenValue);
    // event Transfer(address indexed From, address indexed To, uint256 tokenValue);
    
    modifier lockSwap{inSwapAndLiquify =true; _; inSwapAndLiquify = false;}

    constructor() public {
        refOwned[msgSender()] = totalReflection;
        uniswapV2Router = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        
        // Exclude owner and this contract from fee
        isExcludedFromFee[getOwner()] = true;
        isExcludedFromFee[address(this)] = true;
        emit Transfer(address(0), msgSender(), totalSupply);
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
         balances[account] = balances[account].sub(amount);
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
    
    function getName() public override view returns(string memory) {
        return name;
    }
    
    function getSymbol() public override view returns(string memory) {
        return symbol;
    }
    
    function getDecimals() public override view returns(uint8) {
        return 18;
    }
    
    function getTotalSupply() public override view returns(uint256) {
        return totalSupply;
    }
    
    function balanceOf(address account) public override view returns(uint256) {
        if(isExcluded[account]) return tokensOwned[account];
        return tokenFromReflection(refOwned[account]);
        //return balances[account];
    }
    
    function allowance(address owner, address spender) public override view returns(uint256) {
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
    function increaseAllowance(address spender, uint256 addedVal) external virtual returns(bool) {
         allowances[msgSender()][spender] = allowances[msgSender()][spender].add(addedVal);
         return true;
     }
     
    function decreaseAllowance(address spender, uint256 subtractedVal) external virtual returns(bool) {
         require(subtractedVal<=allowances[msgSender()][spender], "ERC20: Insufficient allowance to be subtracted");
         allowances[msgSender()][spender] = allowances[msgSender()][spender].sub(subtractedVal);
         return true;
     }
    
    function transfer(address recipient, uint256 amount) public override returns(bool) {
        _transfer(msgSender(), recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {
        // Caller is approved to spend more than "amount" tokens belongs to the sender.
        require(amount <= allowances[sender][msgSender()]);
        _transfer(sender, recipient, amount);
        allowances[sender][msgSender()] = allowances[sender][msgSender()].sub(amount);
        return true;
    }
    
    function isExcludedFromRewards(address account) public view returns(bool) {
        return isExcluded[account];
    }
    
    function getTotalFees() public view returns (uint256) {
        return totalFees;
    }
    
    function reflect(uint256 tokenAmount) public {
        require(!isExcluded[msgSender()], "Excluded address cannot call this function");
        (uint256 refAmount,,,,,) = getValues(tokenAmount);
        refOwned[msgSender()] = refOwned[msgSender()].sub(refAmount);
        totalReflection = totalReflection.sub(refAmount);
        totalFees = totalFees.add(tokenAmount);
    }
    
    function refelectionFromToken(uint256 tokenAmount, bool transferFeeDeducted) public view returns(uint256) {
        require(tokenAmount<=totalSupply, "Amount must be less than supply");
        if (!transferFeeDeducted) {
            (uint256 refAmount,,,,,) = getValues(tokenAmount);
            return refAmount;
        } else {
            (,refTransferAmount,,,,) = getValues(tokenAmount);
            return refTransferAmount;
        }
    }
    
    function tokenFromReflection(uint256 refAmount) public view returns(uint256){
        require(refAmount<=totalReflection, "Amount must be less than total refections");
        return refAmount.div(getRate());
    }
    
    function excludeFromReward(address account) public onlyOwner() {
        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!isExcluded[account], "The account is already excluded");
        if(refOwned[account]>0) {
            tokensOwned[account] = tokenFromReflection(refOwned[account]);
        }
        isExcluded[account] = true;
        excluded.push(account);
    }
    
    function includeFromReward(address account) external onlyOwner() {
        require(isExcluded[account], "The account is already included");
        for(uint256 i=0;i<excluded.length;i++) {
            if(excluded[i]==account) {
                excluded[i] = excluded[excluded.length - 1]; //Replaced by the last item
                tokensOwned[account] = 0;
                isExcluded[account] = false;
                excluded.pop(); // Pop up the last item
                break;
            }
        }
    }
 }
