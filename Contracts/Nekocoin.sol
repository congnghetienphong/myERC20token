// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_msgSender() == owner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCallWithValue(target, data, 0);
    }
     
    function functionCallWithValue(address target, bytes memory data, uint256 weiVal) internal returns(bytes memory) {
       require(weiVal<=address(this).balance, "Address: Insufficent balance");
       require(isContract(target), "Address: call to non-contract");
       // solhint-disable-next-line avoid-low-level-calls
       (bool success, bytes memory returndata) = target.call{ value: weiVal }(data);
       if (success) {
           return returndata;
       }else {
          if(returndata.length>0){
           // The easiest way to bubble the revert reason is using memory via assembly
           // solhint-disable-next-line no-inline-assembly
           assembly {let returndata_size := mload(returndata) revert(add(32, returndata), returndata_size)}
          }else {
              revert("Address: low-level call with value failed");
          }
       }
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

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
