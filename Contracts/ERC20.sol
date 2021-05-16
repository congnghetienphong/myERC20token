// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";

contract Nekocoin is Context, IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    string private constant _name = 'Neko';
    string private constant _symbol= 'NEKO';
    uint8 private constant _decimals = 18;
    
    uint256 private constant _totalSupply = 10**9*10**uint256(_decimals); // 1 billion of nekocoins issued in Genesis.
    uint256 private _totalReward; // Accrued reward to be redistributed;
    uint256 private _burned; // Total amount of tokens have been burned.
    uint256 private constant thresholdAmount = 10**6*10**uint256(_decimals); // The threshold amount of tokens the contract hold to launch a swapAndLiquify event.
    uint256 private constant reflectRate = 1; // The rate of static rewarding and burnning reflected from transferred tokens.
    uint256 private constant liquifyRate = 1; // 1% of transferred tokens to be added as liquidity.
    
    mapping(address => uint256) private balances; // The tokens owned by the account before scaled by reflection.
    mapping(address => mapping(address => uint256)) private allowances;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    // Check if the contract is in the procedure of swapping and liquifying, to avoid repeating before this.balance has changed.
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true; // In case to lock this function
    
    event SwapAndLiqEnabled(bool enabled); // Announce the updated state about the availability of swapping and liquifying
    event SwapAndLiquify(uint256 nekoSwapped, uint256 bnbReceived, uint256 nekoIntoLiquidity);
    
    // Lock the contract to assure no more swapping and liquifying can be executed before the current procedure has been done.
    modifier lockTheSwap{inSwapAndLiquify=true; _; inSwapAndLiquify=false;}

    constructor() public {
        _totalReward = 0;
        _burned = 0;
        balances[_msgSender()] = _totalSupply;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        // Create a uniswap pair for new created nekocoins
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    // To recieve BNB from uniswapV2Router when swaping
    receive() external payable {}
    
    function name() public view override returns(string memory) {
        return _name;
    }
    
    function symbol() public view override returns(string memory) {
        return _symbol;
    }
    
    function decimals() external view override returns(uint8) {
        return _decimals;
    }
    
    function totalSupply() public override view returns(uint256) {
        return _totalSupply;
    }
    
    function totalReward() public view returns(uint256) {
        return _totalReward;
    }
    
    function burned() public view returns(uint256) {
        return _burned;
    }
    
    function balanceOf(address account) public override view returns(uint256) {
        // Get the scaled amount of neko by multiplying real time exchange rate
        return balances[account].mul(exRate());
    }
    
    function transfer(address recipient, uint256 amount) public override returns(bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public override view returns(uint256) {
        return allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {
        require(amount <= allowances[sender][_msgSender()], "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), allowances[sender][_msgSender()] - amount);
        _transfer(sender, recipient, amount);
        return true;
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
         allowances[_msgSender()][spender] = allowances[_msgSender()][spender].add(addedVal);
         return true;
     }
     
    function decreaseAllowance(address spender, uint256 subtractedVal) external virtual returns(bool) {
         require(subtractedVal<=allowances[_msgSender()][spender], "ERC20: Insufficient allowance to be subtracted");
         allowances[_msgSender()][spender] = allowances[_msgSender()][spender].sub(subtractedVal);
         return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender!=address(0), "ERC20: transfer from the zero address");
        require(recipient!=address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender), "ERC20: transfer amount exceeds balance");
        // Is the token balance of this contract address over the threshold amount to initiate a swap + liquidity event?
        // Also, don't get caught in a circular liquidity event (inSwapAndLiquify).
        // Also, don't swap & liquify if sender is uniswap pair.
        uint256 contractNekoBalance = balanceOf(address(this));
        bool overLiquifyThreshold = contractNekoBalance >= thresholdAmount;
        if(overLiquifyThreshold && !inSwapAndLiquify && sender!=uniswapV2Pair && swapAndLiquifyEnabled) {
            // Add liquidity
            swapAndLiquify(thresholdAmount);
        }
        tokenTransfer(sender, recipient, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner!=address(0), "ERC20: approve from the zero address");
        require(spender!=address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function setSwapAndLiqEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiqEnabled(enabled);
    }
    
    function getValues(uint256 amount) private view returns(uint256, uint256, uint256, uint256, uint256) {
        (uint256 transferredAmount, uint256 taxForReflect, uint256 taxForLiquify) = getTaxVals(amount);
        (uint256 reward, uint256 burn) = getReflectVals(taxForReflect, burnedRatio());
        return(transferredAmount, taxForReflect, taxForLiquify, reward, burn);
    }
    
    // Calculate the pre-reflection amount of transfered tokens and tax to be reflected and liquified in a trade.
    function getTaxVals(uint256 amount) private view returns(uint256, uint256, uint256) {
        uint256 transferredAmount = amount.div(exRate()); // back to no refelction state
        uint256 taxForReflect = transferredAmount.mul(reflectRate).div(100); // reflection for reward and burnning
        uint256 taxForLiquify = transferredAmount.mul(liquifyRate).div(100); // 1% for liquidity pool
        return(transferredAmount, taxForReflect, taxForLiquify);
    }
    
    // Calculate the pre-reflection amount of static reward and tokens to be burned.
    function getReflectVals(uint256 taxForRef, uint256 burnedRate) private pure returns(uint256, uint256) {
        uint256 reward = taxForRef.mul(burnedRate); // Multiplied by burned percentage.
        uint256 burn = taxForRef.mul(1 - burnedRate); // Multiplied by circulation percentage.
        return(reward, burn);
    }
    
    // The burend ratio from total supply determines the proportion of reward and burn in tax.
    function burnedRatio() private view returns(uint256) {
        return _burned.div(_totalSupply);
    }
    
    // Get the exchange rate between the no-reward balance and the actual balance
    function exRate() private view returns(uint256) {
        return _totalReward.div(_totalSupply) + 1;
    }
    
    function tokenTransfer(address sender, address recipient, uint256 amount) private {
        (uint256 transferredAmount, uint256 taxForReflect, uint256 taxForLiquify, uint256 reward, uint256 burn) = getValues(amount);
        // Tax will be deducted from sender's account.
        balances[sender] = balances[sender].sub(transferredAmount).sub(taxForReflect).sub(taxForLiquify);
        balances[recipient] = balances[recipient].add(transferredAmount);
        _totalReward.add(reward);
        _totalSupply.sub(burn); 
        _burned.add(burn);
        // Add tax to the address of this contract for liquifying.
        balances[address(this)] = balances[address(this)].add(taxForLiquify);
        emit Transfer(sender, address(this), taxForLiquify);
        emit Transfer(sender, address(0), burn);
        emit Transfer(sender, recipient, amount);
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves for adding liquidity
        uint256 half = contractTokenBalance.div(2);
        uint256 halfForBNB = contractTokenBalance.sub(half);
        
        // Capture the contract's current BNB balance.
        uint256 initialBalance = address(this).balance;
        
        // Swap tokens for BNB.
        swapTokensForBNB(halfForBNB);
        
        // How much BNB did we just swap into?
        uint256 swapedBNB = address(this).balance.sub(initialBalance);
        
        addLiquidity(half, swapedBNB); // Add liquidity to uniswap
        buyback(); // Use remaining BNB to buyback Neko coins.
        emit SwapAndLiquify(halfForBNB, swapedBNB, half);
    }
    
    function swapTokensForBNB(uint256 tokenAmount) private {
        // Generate the uniswap pair path of neko -> wbnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }
    
    function swapBNBForToken(uint256 bnbAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);
        _approve(address(this), address(uniswapV2Router), bnbAmount);
         
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount} (
            0, // Accept any amount of Neko.
            path,
            address(this),
            block.timestamp
        );
    }
    
    function buyback() private {
        uint256 fund = address(this).balance;
        // Always keep >=10 BNB For potential gas cost
        if(fund>1000) swapBNBForToken(fund-10);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0,
            owner(),
            block.timestamp
        );
    }
 }
