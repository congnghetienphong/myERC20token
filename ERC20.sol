// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    // Returns the amount of tokens in existence.
    function getTotalSupply() external view returns (uint256);
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

/**
 * @dev Interface for the optional extended functions from the ERC20 standard.
 */
 
interface IERC20Extended is IERC20 {
    /**
     * @dev Interface for the optional extended functions from the ERC20 standard.
     * 
     * Returns the name of the token.
     */
    function getName() external view returns (string memory);
    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function getSymbol() external view returns (string memory);
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
    function getDecimals() external view returns (uint8);
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

/**
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
    function msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    function msgData() internal view virtual returns (bytes calldata) {
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        this;
        return msg.data;
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
     */
     function isContract(address account) internal view returns(bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codeHash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codeHash:=extcodehash(account)}
        return(codeHash!=accountHash && codeHash!= 0x0);
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
     function sendVal(address payable recipient, uint256 amount) internal {
         require(amount<=address(this).balance, "Address: insufficient balance");
         // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
         (bool success, ) = recipient.call{ value: amount }("");
         require(success, "Adress: unable to send value, recipient may have reverted");
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
    address private owner;
    address private previousOwner;
    uint256 private unlockTime;
     
    event ownershipTransferred(address indexed previousOwner, address indexed newOwner);
     
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = msgSender();
        owner = msgSender;
        emit ownershipTransferred(address(0), msgSender);
    }
     
    // Returns the address of the current ownershipTransferred
    function getOwner() public view returns (address) {
        return owner;
    }
    
    function getPreviousOwner() public view returns (address) {
        return previousOwner;
    }
    
    function getUnlockTime() public view returns(uint256) {
        return unlockTime;
    }
     
    // Check whether the caller is the current owner or not
    modifier onlyOwner {
        require(msgSender()==owner, "Ownable: caller is not the owner");
        _;
    }
     
    /**
     * @dev Leaves the contract without owner.
     * Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     */
    function renounceOwnership() public virtual onlyOwner {
        emit ownershipTransferred(owner, address(0));
        owner = address(0);
    }
     
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner!=address(0), "Ownable: new owner is the zero address");
        emit ownershipTransferred(owner, newOwner);
        owner = newOwner;
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
