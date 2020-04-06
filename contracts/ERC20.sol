pragma solidity >= 0.4.24;

import "./Ownable.sol";
import "./SafeMath.sol";

contract ERC20 is Ownable {

    using SafeMath for uint256;

    event Transfer(address indexed from, address indexed to, uint256 indexed value);
    event Approval(address indexed owner, address indexed spender, uint256 indexed value);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;

    mapping (address => bool) _trusted; //address allowed to transfer from owner
    
    string private _name;
    string private _ticker;
    uint private _totalSupply;
    uint8 private _decimals;

    constructor(string memory name, string memory ticker, uint totalSupply, uint8 decimals) public {
        _name = name;
        _ticker = ticker;
        _totalSupply = totalSupply;
        _decimals = decimals;
        _mint(owner(), _totalSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function ticker() public view returns (string memory) {
        return _ticker;
    }


    function balanceOf(address _address) public view returns (uint256) {
        return _balances[_address];
    }




    function addTrusted(address _address) public onlyOwner() returns (bool ){
        require(_address != address(0), "address 0x0");
        _trusted[_address] = true;
        return true;
    }

    modifier onlyTrusted() {
        require(_trusted[msg.sender], "not trusted adress");
        _;
    }




    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        _transfer(_from, _to, _value);
        return true;
    }

    function transferFromTrusted(address _to, uint256 _value) public onlyTrusted() returns (bool) {
        _approve(owner(), _to, _value);
        _transfer(owner(), _to, _value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "address 0x0");

        require(value <= _balances[from], "not enough fund");
        require(value <= _allowed[from][msg.sender], "transfer not allowed");

        _balances[from] -= value;
        _balances[to] += value;
        _allowed[from][msg.sender] -= value;

        emit Transfer(from, to, value);
    }

    function _mint(address _receiver, uint256 _value) internal onlyOwner() {
        require(_receiver != address(0), "address 0x0");
        _totalSupply = _totalSupply.add(_value);
        _balances[_receiver] = _balances[_receiver].add(_value);
        emit Transfer(address(0), _receiver, _value);
    }




    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function _approve(address sender, address spender, uint256 value) internal {
        require(spender != address(0), "address 0x0");
        require(sender != address(0), "address 0x0");

        _allowed[sender][spender] = value;
        emit Approval(sender, spender, value);
    }

    function allowance(address sender, address spender) public view returns (uint256) {
        return _allowed[sender][spender];
    }
}
