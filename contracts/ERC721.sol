pragma solidity >=0.4.24;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";

contract ERC721 is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    mapping (uint => address) private _tokenOwner;
    mapping (uint => address) private _tokenApprovals;
    mapping (address => Counters.Counter) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // mint new token to a given address from 2 existing tokens
    // caller has to be owner of the 2 given tokens
    function mintFromTwo(uint256 tokenId1, uint256 tokenId2, uint256 newTokenId, address to) public {
      require(msg.sender == _tokenOwner[tokenId1], 'mint from two: not owner of token 1');
      require(msg.sender == _tokenOwner[tokenId2], 'mint from two: not owner of token 2');
      _mint(to, newTokenId);
    }

    function balanceOf(address owner) public view returns (uint) {
        require(owner != address(0), "address 0x0");
        return _ownedTokensCount[owner].current();
    }

    function ownerOf(uint tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "address 0x0");
        return owner;
    }

    function transferFrom(address from, address to, uint tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "");
        _transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint tokenId) public {
        transferFrom(from, to, tokenId);
    }

    function _exists(uint tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    function mintToken(address to, uint tokenId) public {
        _mint(to, tokenId);
    }

    function burnToken(address owner, uint tokenId) public {
        _burn(owner, tokenId);
    }

    function _mint(address to, uint tokenId) internal {
        require(to != address(0), "address 0x0");
        require(!_exists(tokenId), "token already exists");
        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();
        emit Transfer(address(0), to, tokenId);
    }
    
    function _burn(address _address, uint tokenId) internal {
        require(ownerOf(tokenId) == _address, "not owner of token");
        _clearApproval(tokenId);
        _ownedTokensCount[_address].decrement();
        _tokenOwner[tokenId] = address(0);
        emit Transfer(_address, address(0), tokenId);
    }

    function _transferFrom(address from, address to, uint tokenId) internal {
        require(ownerOf(tokenId) == from, "not owner of token");
        require(to != address(0), "address 0x0");
        _clearApproval(tokenId);
        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();
        _tokenOwner[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function approve(address to, uint tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "you approve for the owner of the token");
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "");
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function tokenApproved(address to, uint tokenId) public view returns (bool) {
        return _isApprovedOrOwner(to, tokenId);
    }

    function getApproved(uint tokenId) public view returns (address) {
        require(_exists(tokenId), "token doesn't exist");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender, "you approve for yourself");
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(address spender, uint tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _clearApproval(uint tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}
