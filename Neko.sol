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
    uint8 private constant decimals = 9;
    
    uint256 private totalSupply = 10**15; // 100 trillion of neko issued in Genesis.
    uint256 private totalReward; // Accrued reward to be redistributed;
    uint256 private burned; // Total amount of tokens have been burned.
    uint256 private constant maxTxAmount = 10**12; // Limit the maximum transaction amount to prevent token price from manipulating.
    uint256 private constant thresholdAmount = 10**9; // The threshold amount of tokens the contract hold to launch a swapAndLiquify event.
    uint256 private constant reflectRate = 1; // The rate of static rewarding and burnning reflected from transferred tokens.
    uint256 private constant liquifyRate = 1; // 1% of transferred tokens to be added as liquidity.
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    // Check if the contract balance is in the procedure of swapping and liquifying, to avoid repeating before this.balance has changed.
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true; // In case to lock this function

    mapping(address => uint256) private balances; // The tokens owned by the account except from rewards.
    mapping(address => uint256) private actualBalances; // The tokens owned by the account combined with rewards by a dynamic rate.
    mapping(address => mapping(address => uint256)) private allowances;
    
    event SwapAndLiqEnabled(bool enabled); // Announce the updated state about the availability of swapping and liquifying
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    
    // Lock the contract to assure no more swapping and liquifying can be executed before the current procedure has been done.
    modifier lockTheSwap{inSwapAndLiquify=true; _; inSwapAndLiquify=false;}

    constructor() {
        totalReward = 0;
        burned = 0;
        balances[msgSender()] = totalSupply;
        actualBalances[msgSender()] = totalSupply;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        emit Transfer(address(0), msgSender(), totalSupply);
    }
    
    // To recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner!=address(0), "ERC20: approve from the zero address");
        require(spender!=address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function getName() external view virtual override returns(string memory) {
        return name;
    }
    
    function getSymbol() external view virtual override returns(string memory) {
        return symbol;
    }
    
    function getDecimals() external view virtual override returns(uint8) {
        return decimals;
    }
    
    function getTotalSupply() public override view returns(uint256) {
        return totalSupply;
    }
    
    function getTotalReward() public view returns(uint256) {
        return totalReward;
    }
    
    function balanceOf(address account) public override view returns(uint256) {
        return actualBalances[account];
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
        // Caller must be approved to spend more than "amount" tokens belongs to the sender.
        require(amount <= allowances[sender][msgSender()]);
        _transfer(sender, recipient, amount);
        allowances[sender][msgSender()] = allowances[sender][msgSender()].sub(amount);
        return true;
    }
    
    function setSwapAndLiqEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiqEnabled(enabled);
    }
    
    function getValues(uint256 amount) private view returns(uint256, uint256, uint256, uint256) {
        (uint256 taxForReflect, uint256 taxForLiquify) = getTaxVals(amount);
        (uint256 reward, uint256 burn) = getReflectVals(taxForReflect, getBurnedRate());
        return(taxForReflect, taxForLiquify, reward, burn);
    }
    
    // Calculate the amount of tax to be reflected and liquified in a trade.
    function getTaxVals(uint256 amount) private pure returns(uint256, uint256) {
        uint256 taxForReflect = amount.mul(reflectRate).div(100); // reflection for reward and burnning
        uint256 taxForLiquify = amount.mul(liquifyRate).div(100); // 1% for liquidity pool
        return(taxForReflect, taxForLiquify);
    }
    
    // Calculate actual amount of static reward and tokens to be burned.
    function getReflectVals(uint256 taxForRef, uint256 burnedRate) private pure returns(uint256, uint256) {
        uint256 reward = taxForRef.mul(burnedRate); // Multiplied by burned percentage.
        uint256 burn = taxForRef.mul(1 - burnedRate); // Multiplied by circulation percentage.
        return(reward, burn);
    }
    
    // The burend rate determines the proportion of reward and burn in tax.
    function getBurnedRate() private view returns(uint256) {
        return burned.div(totalSupply);
    }
    
    // Get the exchange rate between the original balance and the actual balance
    function getExRate() private view returns(uint256) {
        return totalReward.div(totalSupply) + 1;
    }
    
    function tokenTransfer(address sender, address recipient, uint256 amount) private {
        (uint256 taxForReflect, uint256 taxForLiquify, uint256 reward, uint256 burn) = getValues(amount);
        // Tax will be deducted from sender's account.
        actualBalances[sender] = actualBalances[sender].sub(amount).sub(taxForReflect).sub(taxForLiquify);
        balances[sender] = actualBalances[sender].div(getExRate()); // Update original account balance.
        actualBalances[recipient] = actualBalances[recipient].add(amount);
        balances[recipient] = balances[recipient].div(getExRate());
        totalReward.add(reward);
        totalSupply.sub(burn); 
        burned.add(burn);
        balances[address(this)] = balances[address(this)].add(taxForLiquify);
        emit Transfer(sender, address(this), reward);
        emit Transfer(sender, address(0), burn);
        emit Transfer(sender, recipient, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender!=address(0), "ERC20: transfer from the zero address");
        require(recipient!=address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender), "ERC20: transfer amount exceeds balance");
        require(amount <= maxTxAmount, "ERC20: transfer amount exceeds maxTxAmount");
        // Is the token balance of this contract address over the threshold amount to initiate a swap + liquidity event?
        // Also, don't get caught in a circular liquidity event (inSwapAndLiquify).
        // Also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overLiquifyThreshold = contractTokenBalance >= thresholdAmount;
        if(overLiquifyThreshold && !inSwapAndLiquify && sender!=uniswapV2Pair && swapAndLiquifyEnabled) {
            // Add liquidity
            swapAndLiquify(thresholdAmount);
        }
        tokenTransfer(sender, recipient, amount);
        // Use remaining BNB to buyback Neko coins.
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves for adding liquidity
        uint256 half = contractTokenBalance.div(2);
        uint256 halfForETH = contractTokenBalance.sub(half);
        
        // Capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialETHBalance = address(this).balance;
        
        // Swap tokens for ETH.
        swapTokensForETH(halfForETH); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        
        // how much ETH did we just swap into?
        uint256 swapedETH = address(this).balance.sub(initialETHBalance);
        
        addLiquidity(half, swapedETH); // Add liquidity to uniswap
        buyback(); // Use remaining BNB to buyback Neko coins.
        emit SwapAndLiquify(halfForETH, swapedETH, half);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this),
            block.timestamp);
    }
    
    function swapBNBForNeko(uint256 BNB) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
         _approve(address(this), address(uniswapV2Router), BNB);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens(
            0, // Accept any amount of Neko.
            path,
            address(this),
            block.timestamp);
    }
    
    function buyback() private {
        // Always keep >=10 BNB For potential gas cost.
        uint256 fund = address(this).balance - 10;
        if(fund>1000) swapBNBForNeko(fund);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0,
            getOwner(),
            block.timestamp);
    }
 }
