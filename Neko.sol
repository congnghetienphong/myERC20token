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
    * @dev The ERC-20 standard allow an owner topermit a spender
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

contract Neko is IERC20 {
    string public constant name = 'Nekocoin';
    string public constant symble = "NEKO';
    uint8 public constant decimals = 18;
    uint256 total_supply = 100000000000000; // 100 trillion of Nekocoins issued in Genesis
    using safemath for total_supply;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    event Approval(address indexed tokenOwner, address indexed permittedSpender, uint256 tokenValue);
    event Transfer(adress indexed from, address indexed to, uint256 tokenValue);

    constructor(uint256 totalAmount) public {
        total_supply = totalAmount;
        balances[msg.sender] = total_supply;
    }
    
    function totoalSupply() public override view returns (uint256) {
        return total_supply;
    }
    
    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }
    
    function allowance(address owner, address spender) public override view returns (uint256) {
        return allowed[owner][spender];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(
            amount <= balances[msg.sender], 
            "The amount of tokens you are trying to transfer is more than your can afford"
        );
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[recipent] = balances[recipient].add(amount);
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) override returns (bool) {
        require(amount <= balances[sender]);
        require(amount <= allowed[sender][msg.sender]);
        balances[sender] = balances[sender].sub(amount);
        allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(amount);
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
/**   
    struct beneficiary{
        address receiver;
        uint256 amount;
        bool received;
    }
    enum face{face1, face2, face3} // The face of the coin
    // Certanin number of necos has been issued to a list of benificiaries
    event nekoIssued(address benificiary, uint256 amount);
    
    
    modifier onlyIssuer(){
    require(
         msg.sender == nekosama, // If not the nekoSama call this contract
         "only nakosama can issue Necos." // Reject the require and claim
    );
    _; // Otherwise execute the function
    }
    
    /**
    * @dev Issue a given number of Neko at a time
    * @param num value to issue
    *
   function issue(uint256 num) public onlyIssuer{

    }
*/    
    
    // A library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
    library SafeMath {
        function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
            assert((c=a+b)>=a, 'ds-math-add-overflow');
        }
        
        function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
            assert((c=a-b)<=a, 'ds-math-sub-underflow')
        }
        
        function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
            assert(b==0||(c=a*b)/b=a, 'ds-math-mul-overflow')
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
 }
