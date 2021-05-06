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
    
    uint256 private constant MAX = ~uint256(0);
    uint256 private totalSupply = 10**15; // 100 trillion of Nekocoins issued in Genesis.
    uint256 private totalRewardRemained = MAX - MAX%totalSupply; // Static reward, also called reflection.
    uint256 private totalRewardReflected; // Total amount of static reward has been distributed.
    
    uint256 public rewardRate = 0.05; // The rate of rewards reflected from transferred tokens.
    uint256 private previousrewardRate = rewardRate;
    uint256 public liquifyRate = 0.05; // 5% of transferred tokens to be added as liquidity.
    uint256 private previousLiqfyRate = liquifyRate;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    // Check if the contract balance is in the procedure of swapping and liquifying, to avoid repeating before this.balance has changed.
    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true; // In case to lock this function
    
    uint256 public maxTxAmount = 10**12; // 100 billion tokens in a single transaction at most.
    uint256 private liquifyThreshold = 10**10; // The threshold amount of tokens the contract hold to launch a swapAndLiquify event.

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    mapping(address => uint256) private rewardOwned; // The accrued reward already owned by the account.
    mapping(address => uint256) private tokensOwned; // The neko coin owned by the account.
    
    address[] private excluded; // Accounts that are excluded from the static reward.
    // Check if the account is excluded from the trading fee(for static reward and liquidity) or not.
    mapping(address => bool) private isExcludedFromFee;
    mapping(address => bool) private isExcluded; // From static reward
    
    // event minTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap); // Found nowhere to use.
    event swapAndLiqEnabled(bool enabled); // Announce the updated state about the availability of swapping and liquifying
    event swapAndLiqComplete(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    
    // Lock the contract to assure no more swapping and liquifying can be executed before the current one has been done.
    modifier lockTheSwap{inSwapAndLiquify=true; _; inSwapAndLiquify=false;}

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
        return totalTaxFees;
    }
    
    function reflect(uint256 tokenAmount) public {
        require(!isExcluded[msgSender()], "Excluded address cannot call this function");
        (uint256 refAmount,,,,,) = getValues(tokenAmount);
        refOwned[msgSender()] = refOwned[msgSender()].sub(refAmount);
        totalReflection = totalReflection.sub(refAmount);
        totalTaxFees = totalTaxFees.add(tokenAmount);
    }
    
    function refelectionFromToken(uint256 tokenAmount, bool transferFeeDeducted) public view returns(uint256) {
        require(tokenAmount<=totalSupply, "Amount must be less than supply");
        if (!transferFeeDeducted) {
            (uint256 refAmount,,,,,) = getValues(tokenAmount);
            return refAmount;
        } else {
            (,uint256 refTransferAmount,,,,) = getValues(tokenAmount);
            return refTransferAmount;
        }
    }
    
    function tokenFromReflection(uint256 refAmount) public view returns(uint256){
        require(refAmount<=totalReflection, "Amount must be less than total refections");
        return refAmount.div(getRate());
    }
    
    function excludeFromReward(address account) public onlyOwner {
        require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!isExcluded[account], "The account is already excluded");
        if(refOwned[account]>0) {
            tokensOwned[account] = tokenFromReflection(refOwned[account]);
        }
        isExcluded[account] = true;
        excluded.push(account);
    }
    
    function includeFromReward(address account) external onlyOwner {
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
    
    function excludeFromFee(address account) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        isExcludedFromFee[account] = false;
    }
    
    function checkIsExcludedFromFee(address account) public view returns(bool) {
        return isExcludedFromFee[account];
    }
    
    function setTaxPercent(uint256 tax) external onlyOwner {
        taxFee = tax;
    }
    
    function setLiquidityFeePercent(uint256 liqFee) external onlyOwner {
        liquidityFee = liqFee;
    }
    
    function setMaxTxPercent(uint256 maxTxPerc) external onlyOwner {
        maxTxAmount = totalSupply.mul(maxTxPerc).div(10**2);
    }
    
    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }
    
    // To recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
    
    function reflectFee(uint256 refFee, uint256 taxFee) private {
        totalReflection = totalReflection.sub(refFee);
        totalTaxFees = totalTaxFees.add(taxFee);
    }
    
    function getValues(uint256 tokenAmount) private view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tokenTransferAmount, uint256 taxFee, uint256 liqFee) = getTokenVals(tokenAmount);
        (uint256 refAmount, uint256 refTransferAmount, uint256 refFee) = getRefVals(tokenAmount, taxFee, liqFee, getRate());
        return(refAmount, refTransferAmount, refFee, tokenTransferAmount, taxFee, liqFee);
    }
    
    function getTokenVals(uint256 tokenAmount) private view returns(uint256, uint256, uint256) {
        uint256 taxFee = calculateTaxFee(tokenAmount);
        uint256 liqFee = calculateLiqFee(tokenAmount);
        uint256 tokenTransferAmount = tokenAmount.sub(taxFee).sub(liqFee); // 5% for holder and 5% for liquidity pool
        return(tokenTransferAmount, taxFee, liqFee);
    }
    
    function getRefVals(uint256 tokenAmount, uint256 taxFee, uint256 liqFee, uint256 currRate) 
    private pure returns(uint256, uint256, uint256) {
        uint256 refAmount = tokenAmount.mul(currRate);
        uint256 refFee = taxFee.mul(currRate);
        uint256 refLiquidity = liqFee.mul(currRate);
        uint256 refTransferAmount = refAmount.sub(refFee).sub(refLiquidity);
        return(refAmount, refTransferAmount, refFee);
    }
    
    function getRate() private view returns(uint256) {
        (uint256 refSupply, uint256 tokenSupply) = getCurrSupply();
        return refSupply.div(tokenSupply);
    }
    
    function getCurrSupply() private view returns(uint256, uint256) {
        uint256 refSupply = totalReflection;
        uint256 tokenSupply = totalSupply;
        for(uint256 i=0;i<excluded.length;i++) {
            if(refOwned[excluded[i]]>refSupply||tokensOwned[excluded[i]]>tokenSupply) return(totalReflection, totalSupply);
            refSupply = refSupply.sub(refOwned[excluded[i]]);
            tokenSupply = tokenSupply.sub(tokensOwned[excluded[i]]);
        }
        if(refSupply<totalReflection.div(totalSupply)) return(totalReflection, totalSupply);
        return(refSupply, tokenSupply);
    }
    
    function takeLiquidity(uint256 liqFee) private {
        uint256 currRate = getRate();
        uint256 refLiquidity = liqFee.mul(currRate);
        refOwned[address(this)] = refOwned[address(this)].add(refLiquidity);
        if(isExcluded[address(this)])
            tokensOwned[address(this)] = tokensOwned[address(this)].add(liqFee); 
    }
    
    function calculateTaxFee(uint256 tokenAmount) private view returns(uint256) {
        return tokenAmount.mul(taxFee).div(10**2);
    }
    
    function calculateLiqFee(uint256 tokenAmount) private view returns(uint256) {
        return tokenAmount.mul(liquidityFee).div(10**2);
    }
    
    function removeAllFee() private {
        if(taxFee==0 && liquidityFee==0) return;
        previousTaxFee = taxFee;
        previousLiqFee = liquidityFee;
        taxFee = 0;
        liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        taxFee = previousTaxFee;
        liquidityFee = previousLiqFee;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender!=address(0), "ERC20: transfer from the zero address");
        require(recipient!=address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(sender!=getOwner()  && recipient != getOwner())
            require(amount <= maxTxAmount, "ERC20: transfer amount exceeds the maxTxAmount");
         
        // Is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // Also, don't get caught in a circular liquidity event.
        // Also, don't swap & liquify if sender is uniswap pair.
         
        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= maxTxAmount) contractTokenBalance = maxTxAmount; // In initiation
        bool overMinTokenBalance = contractTokenBalance >= tokensSellToAddLiq;
        if(overMinTokenBalance && !inSwapAndLiquify && sender!=uniswapV2Pair && swapAndLiquifyEnabled) {
            contractTokenBalance = tokensSellToAddLiq;
            // Add liquidity
            swapAndLiquify(contractTokenBalance);
        }
        //indicates if fee should be deducted from transfer
        bool takeFee = true;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) takeFee = false;
        //transfer amount, it will take tax, burn, liquidity fee
        tokenTransfer(sender, recipient, amount, takeFee);
        // balances[sender] = balances[sender].sub(amount);
        // balances[recipient] = balances[recipient].add(amount);
        // emit Transfer(sender, recipient, amount);
    }
    
    function swapAndLiquify(uint256 contractTokenBalance) private lockSwap {
        // split the contract balance into halves for adding liquidity
        uint256 half = contractTokenBalance.div(2);
        uint256 halfForETH = contractTokenBalance.sub(half);
        
        // Capture the contract's current ETH balance.
        //  this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialETHBalance = address(this).balance;
        
        // swap tokens for ETH
        swapTokensForETH(halfForETH); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered
        
        // how much ETH did we just swap into?
        uint256 swapedETH = initialETHBalance.sub(address(this).balance);
        
        // Add liquidity to uniswap
        addLiquidity(half, swapedETH);
        emit SwapAndLiquify(half, swapedETH, halfForETH);
    }
    
    function swapTokensForETH(uint256 tokenAmount) private {
        // Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        
        approve(address(this), address(uniswapV2Router), tokenAmount);
        
        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of ETH
            path,
            address(this),
            block.timeStamp);
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // Approve token transfer to cover all possible scenarios
        approve(address(this), address(uniswapV2Router), tokenAmount);
        
        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0,
            getOwner(),
            block.timeStamp);
    }
    
    // This method is responsible for taking all fee, if takeFee is true
    function tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee) removeAllFee();
        
        if(isExcluded[sender] && !isExcluded[recipient]) {
            transferFromExcluded(sender, recipient, amount);
        }else if(!isExcluded[sender] && isExcluded[recipient]) {
            transferToExcluded(sender, recipient, amount);
        }else if(isExcluded[sender] && isExcluded[recipient]) {
            transferBothExcluded(sender, recipient, amount);
        }else {
            transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee) restoreAllFee();
    }
    
    function transferStandard(address sender, address recipient, uint256 tokenAmount) private {
        (uint256 rewardAmount, uint256 rewardTransfer, uint256 rewardFee, 
        uint256 tokenTransfer, uint256 taxFee, uint256 liqFee) = getValues(tokenAmount);
        rewardOwned[sender] = rewardOwned[sender].sub(rewardAmount);
        rewardOwned[recipient] = rewardOwned[recipient].add(rewardTransfer);
        takeLiquidity(liqFee);
        reflectFee(rewardFee, taxFee);
        emit Transfer(sender, recipient, tokenTransfer);
    }
    
    function transferToExcluded(address sender, address recipient, uint256 tokenAmount) private {
        (uint256 rewardAmount, uint256 rewardTransfer, uint256 rewardFee, 
        uint256 tokenTransfer, uint256 taxFee, uint256 liqFee) = getValues(tokenAmount);
        rewardOwned[sender] = rewardOwned[sender].sub(rewardAmount);
        tokenOwned[recipient] = tokenOwned[recipient].add(tokenTransfer);
        rewardOwned[recipient] = rewardOwned[recipient].add(rewardTransfer);
        takeLiquidity(liqFee);
        reflectFee(rewardFee, taxFee);
        emit Transfer(sender, recipient, tokenTransfer);
    }
    
    function transferFromExcluded(address sender, address recipient, uint256 tokenAmount) private {
        (uint256 rewardAmount, uint256 rewardTransfer, uint256 rewardFee, 
        uint256 tokenTransfer, uint256 taxFee, uint256 liqFee) = getValues(tokenAmount);
        tokenOwned[sender] = tokenOwned[sender].sub[tokenAmount];
        rewardOwned[sender] = rewardOwned[sender].sub(rewardAmount);
        rewardOwned[recipient] = rewardOwned[recipient].add(rewardTransfer);
        takeLiquidity(liqFee);
        reflectFee(rewardFee, taxFee);
        emit Transfer(sender, recipient, tokenTransfer);
    }
    
    function transferBothExcluded(address sender, address recipient, uint256 tokenAmount) private {
        (uint256 refAmount, uint256 refTranferAmount, uint256 refFee, uint256 tokenTransferAmount, 
        uint256 taxFee, uint256 liqFee) = getValues(tokenAmount);
        tokenOwned[sender] = tokenOwned[sender].sub(tokenAmount);
        refOwned[sender] = refOwned[sender].sub(refAmount);
        tokenOwned[recipient] = tokenOwned[recipient].add(tokenTransferAmount);
        refOwned[recipient] = refOwned[recipient].add(refTranferAmount);
        takeLiquidity(liqFee);
        reflectFee(refFee, taxFee);
        emit Transfer(sender, recipient, tokenAmount);
    }
 }
