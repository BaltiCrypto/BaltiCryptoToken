pragma solidity 0.4.20;

contract ERC20Interface
{
	function totalSupply() public view returns (uint supply) {}
	function balanceOf(address _owner) public view returns (uint balance) {}
	function transfer(address _to, uint _value) public returns (bool success) {}
	function transferFrom(address _from, address _to, uint _value) public returns (bool success) {}
	function approve(address _spender, uint _value) public returns (bool success) {}
	function allowance(address _owner, address _spender) public view returns (uint remaining) {}
	event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);  
}

contract RewardToken is ERC20Interface
{
	struct Account
	{
		uint balance;
		uint lastDividendPoints;
	}

	mapping(address=>Account) balances;
	mapping (address => mapping (address => uint)) allowed;
	uint public totalSupply;
	uint totalDividendPoints;

	event RewardAdded(address sender, uint );

	function dividendsOwing(address account) internal view returns(uint)
	{
		assert(totalDividendPoints >= balances[account].lastDividendPoints);
		uint newDividendPoints = totalDividendPoints - balances[account].lastDividendPoints;
		return (balances[account].balance * newDividendPoints) / totalSupply;
	}

	modifier updateAccount(address account)
	{
		uint owing = dividendsOwing(account);
		if(owing > 0)
		{
		account.transfer(owing);
		}
		balances[account].lastDividendPoints = totalDividendPoints;
		_;
	}

	function disburse() internal
	{
		totalDividendPoints += msg.value;
		RewardAdded(msg.sender, msg.value);
	}

	function _transfer(address _from, address _to, uint _value) updateAccount(_to) updateAccount(msg.sender) internal returns (bool success)
	{
		require(_to != 0x0);
		require(balances[_from].balance >= _value);
		require(balances[_to].balance + _value > balances[_to].balance);
		balances[_from].balance -= _value;
		balances[_to].balance += _value;
		Transfer(_from, _to, _value);
	}

	function transfer(address _to, uint _value) public returns (bool success)
	{
		_transfer(msg.sender, _to, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint _value) public returns (bool success)
	{
		require(_value <= allowed[_from][msg.sender]);
		allowed[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint balance)
	{
		return balances[_owner].balance;
	}

	function approve(address _spender, uint _value) public returns (bool success)
	{
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
	}

	function allowance(address _owner, address _spender) public view returns (uint remaining)
	{
		return allowed[_owner][_spender];
	}
}

contract BaltiCryptoSmartToken is RewardToken
{
	string public name;
	string public symbol;
	uint8 public decimals;
	address public tokenStorage;
	address public creator;

	event Burn(address indexed from, uint256 value);

	function BaltiCryptoSmartToken(string tokenName, string tokenSymbol, uint8 _decimals, uint _totalSupplyinEther, address _tokenStorage)
	{
		name = tokenName;
		symbol = tokenSymbol;
		decimals = _decimals;
		balances[_tokenStorage].balance = _totalSupplyinEther * 10 ** uint(18);
		totalSupply = _totalSupplyinEther * 10 ** uint(18);
		tokenStorage = _tokenStorage;
		creator = msg.sender;
	}

	function() payable
	{
		require(msg.value > 0);
		disburse();
	}

	function updateCreator(address _creator) external
	{
		require(msg.sender == creator);
		require(_creator != address(0));
		creator = _creator;
	}

	function updateTokenStorage(address _tokenStorage) external
	{
		require(msg.sender == creator);
		require(_tokenStorage != address(0));
		tokenStorage = _tokenStorage;
	}

	function burn(uint _value) public returns (bool success)
	{
		require(balances[msg.sender].balance >= _value);
		balances[msg.sender].balance -= _value;
		totalSupply -= _value;
		Burn(msg.sender, _value);
		return true;
	}
}
