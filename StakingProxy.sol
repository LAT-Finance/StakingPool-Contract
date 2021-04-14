pragma solidity ^0.5.17;

contract StakingProxy {
    using SafeMath for uint256;

    struct withdrawData {
        mapping(address => uint256) data;
        uint256 dataSum;
        bool transferred;
    }

    address payable public owner;
    address payable public vault;
    uint256 public eraBlocks;
    bool public stakingEnabled = true;

    mapping(address => uint256) public staking;
    mapping(uint256 => mapping(address => uint256)) public stakingInEra;
    mapping(uint256 => withdrawData) public withdrawal;
    uint256 public stakingPoolSum;
    uint256 public totalReward;

    event Stake(address indexed from, uint256 era, uint256 value);
    event Reward(address indexed to, uint256 era, uint256 value, uint256 stakingValue, uint256 rewardEra);
    event Withdraw(address indexed to, uint256 era, uint256 value);
    event WithdrawTransferred(uint256 era);

    modifier validAddress(address _address) {
        require(_address != address("atx1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq89qwkc")
        && _address != address("atp1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqdruy9j"),
            "invalid address");
        _;
    }

    modifier onlyStakingEnabled() {
        require(stakingEnabled == true, "staking must be enabled");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "only owner can call this function");
        _;
    }

    constructor(address payable _vault, uint256 _eraBlocks) public validAddress(_vault) {
        owner = msg.sender;
        vault = _vault;
        eraBlocks = _eraBlocks;
    }

    function updateVault(address payable _vault) external onlyOwner validAddress(_vault) {
        vault = _vault;
    }

    function enableStaking() external onlyOwner {
        stakingEnabled = true;
    }

    function disableStaking() external onlyOwner {
        stakingEnabled = false;
    }

    function stake() payable external onlyStakingEnabled {
        require(msg.value > 0, "stake value is zero");
        vault.transfer(msg.value);
        staking[msg.sender] = staking[msg.sender].add(msg.value);
        stakingPoolSum = stakingPoolSum.add(msg.value);
        uint256 era = block.number.div(eraBlocks);
        stakingInEra[era][msg.sender] = stakingInEra[era][msg.sender].add(msg.value);
        emit Stake(msg.sender, era, msg.value);
    }

    function reward(address to, uint256 value, uint256 stakingValue, uint256 rewardEra) external onlyOwner {
        staking[to] = staking[to].add(value);
        stakingPoolSum = stakingPoolSum.add(value);
        totalReward = totalReward.add(value);
        uint256 era = block.number.div(eraBlocks);
        stakingInEra[era][to] = stakingInEra[era][to].add(value);
        emit Reward(to, era, value, stakingValue, rewardEra);
    }

    function withdraw(uint256 value) external onlyStakingEnabled {
        require(value > 0, "withdraw value is zero");
        require(staking[msg.sender] >= value, "not enough staking balance");
        uint256 era = block.number.div(eraBlocks);
        staking[msg.sender] = staking[msg.sender].sub(value);
        stakingPoolSum = stakingPoolSum.sub(value);
        withdrawal[era].data[msg.sender] = withdrawal[era].data[msg.sender].add(value);
        withdrawal[era].dataSum = withdrawal[era].dataSum.add(value);
        emit Withdraw(msg.sender, era, value);
    }

    function setWithdrawTransferred(uint256 era) external onlyOwner {
        withdrawal[era].transferred = true;
        emit WithdrawTransferred(era);
    }

    function getWithdrawData(uint256 era, address addr) external view returns (uint256 value, bool transferred) {
        return (withdrawal[era].data[addr], withdrawal[era].transferred);
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
