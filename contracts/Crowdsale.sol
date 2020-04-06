pragma solidity >= 0.4.24;

import "./ERC20.sol";
import "./ReentrancyGuard.sol";

contract Crowdsale is ReentrancyGuard {

    using SafeMath for uint256;

    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

    ERC20 private _token;

    address payable private _owner;

    uint private _rate;
    uint private _weiRaised;

    uint private _minSpent;
    uint private _cap;

    constructor (uint rate, uint minSpent, uint cap, ERC20 token) public {
        require(rate > 0, "rate is negative");
        require(address(token) != address(0), "address 0x0");
        require(_cap > 0, "cap is negative");

        _cap = cap;
        _owner = msg.sender;
        _rate = rate;
        _token = token;
        _minSpent = minSpent;
    }


    function purchaseToken () external payable {
        buyTokens(msg.sender);
    }



    function token() public view returns (ERC20) {
        return _token;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function rate() public view returns (uint) {
        return _rate;
    }

    function weiRaised() public view returns (uint) {
        return _weiRaised;
    }

    function cap() public view returns (uint) {
        return _cap;
    }

    function minSpent() public view returns (uint) {
        return _minSpent;
    }



    modifier onlyOwner() {
        require(msg.sender == _owner, "Owner 0x0");
        _;
    }


    function buyTokens(address beneficiary) public payable {
        uint weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);
        uint tokens = _getTokenAmount(beneficiary, weiAmount);
        _weiRaised = _weiRaised.add(weiAmount);
        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);
        _forwardFunds();
    }

    function _preValidatePurchase(address beneficiary, uint weiAmount) internal {
        require(_weiRaised <= _cap, "cap reached");
        require(beneficiary != address(0), "address 0x0");
        require(weiAmount != 0, "Wei amount = 0");
        require(msg.value >= _minSpent, "wei amount too low");
    }

    function _deliverTokens(address beneficiary, uint tokenAmount) internal {
        _token.transferFrom(_owner, beneficiary, tokenAmount);
    }

    function _processPurchase(address beneficiary, uint tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    function _getTokenAmount(address _address, uint weiAmount) internal view returns (uint) {
        return weiAmount.mul(_rate);
    }

    function _forwardFunds() internal {
        _owner.transfer(msg.value);
    }
}