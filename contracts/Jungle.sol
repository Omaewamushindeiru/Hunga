pragma solidity >=0.4.24;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC721.sol";
import "./ERC20.sol";

contract Jungle is Ownable {
    using SafeMath for uint256;

    event HungaDiscovered(address indexed owner, uint tokenId);
    event HungaDeleted(address indexed owner, uint tokenId);
    event HungaTransfered(address indexed from, address indexed to, uint tokenId);
    event HungaFed(address indexed owner, uint tokenId);

    event AuctionCreated(address indexed seller, uint tokenId);
    event AuctionClaimed(address indexed claimer, uint tokenId);
    event NewBid(address indexed bidder, uint tokenId, uint price);

    enum Rank {Lame, Knight, Duke, Legendary}
    enum HungaType {Solar, Lunar, Radioactive, Disco}

    mapping (uint => address) private _hungaToOwner;
    mapping (address => Hunga[]) private _hungasOfOwner;
    mapping (uint => Hunga) private _hungasById;
    mapping (uint => Auction) private _auctions;
    mapping (uint => bool) private _auctionedhungas;

    uint private _currentId;

    ERC721 private _erc721;
    ERC20 private _erc20;

    uint nonce;

    struct Hunga {
        uint id;

        Rank rank;
        HungaType hungaType;

        uint risk;
        uint reward;

        uint claimCount;
        uint lastClaimed; // time at which owner last claimed

        uint feedToImprove; // number of hungas needed to improve hunga
        uint lastFed; // time at which owner last fed hunga
    }

    struct HungaTrap {
        uint id;

        uint price;

        uint LameRate;
        uint KnightRate;
        uint DukeRate;
    }

    mapping (uint => HungaTrap) private _hungaTraps; //packs

    struct Auction {
        address seller;
        address lastBidder;

        uint startDate;
        uint initialPrice;

        uint priceToBid;
        uint bestOffer;
    }

    constructor(ERC721 erc721, ERC20 erc20) public {
        _erc721 = erc721;
        _erc20 = erc20;
        nonce = 0;
    }



    function getOwnerOfhunga(uint id) public view returns (address) {
        require(_hungaToOwner[id] != address(0), "not hunga");
        return _hungaToOwner[id];
    }

    modifier onlyOwnerOfhunga(uint id) {
        require(msg.sender == _hungaToOwner[id], "Not hunga owner");
        _;
    }



    function getAuctioned(uint id) public view returns (address seller, address lastBidder, uint startDate, uint priceToBid, uint bestOffer) {
        require(_auctionedhungas[id], "not auctioned");
        Auction memory auction = _auctions[id];
        return (auction.seller, auction.lastBidder, auction.startDate, auction.priceToBid, auction.bestOffer);
    }

    function isAuctioned(uint id) public view returns (bool) {
        return _auctionedhungas[id];
    }

    modifier onlyAuctionedhunga(uint id) {
        require(_auctionedhungas[id], "not auctioned hunga");
        _;
    }





    function PRNG() public returns(uint) {
        nonce++;
        return uint(keccak256(abi.encodePacked(nonce, msg.sender, blockhash(block.number - 1))));
    }

    function discoverRank(uint lameRate, uint knightRate, uint dukeRate, uint rng) internal pure returns (Rank){
        require(lameRate + knightRate + dukeRate < 100, "impossible rates");
        require(lameRate > 0 && knightRate > 0 && dukeRate > 0, "rates can't be 0");

        if(rng%100 >= lameRate) return Rank.Lame;
        if(rng%100 >= lameRate + knightRate) return Rank.Knight;
        if(rng%100 >= lameRate + knightRate + dukeRate) return Rank.Duke;
        else return Rank.Legendary;
    }

    function discoverHunga(address to, uint hungaTrapId) public returns (bool) {
        HungaTrap memory hg = _hungaTraps[hungaTrapId]; // gas ?

        require(_erc20.balanceOf(msg.sender) >= hg.price, "not enough peels owned");

        _erc20.transferFrom(msg.sender, _erc20.owner(), hg.price);

        _currentId++;

        uint rnd = PRNG();
        Rank rnk = discoverRank(hg.LameRate, hg.KnightRate, hg.DukeRate, rnd);
        HungaType hngtp = HungaType(rnd % 4);

        uint reward = uint(rnk) * 10 + rnd % ((uint(rnk) + 1) * 10);
        if(reward == 0) reward = 3;
        uint feed = 3;

        Hunga memory hunga = Hunga(_currentId, rnk, hngtp, 90, reward, 0, 0, feed, 0);

        _hungasOfOwner[msg.sender].push(hunga);
        _hungasById[_currentId] = hunga;
        _hungaToOwner[_currentId] = to;

        _erc721.mintToken(to, _currentId);

        return true;
    }





    function _removeFromArray(address owner, uint id) private {
        uint size = _hungasOfOwner[owner].length;
        for (uint index = 0; index < size; index++) {
            Hunga storage hunga = _hungasOfOwner[owner][index];
            if (hunga.id == id) {
                if (index < size - 1) {
                    _hungasOfOwner[owner][index] = _hungasOfOwner[owner][size - 1];
                }
                delete _hungasOfOwner[owner][size - 1];
            }
        }
    }

    function deadHunga(uint id) public onlyOwnerOfhunga(id) {
        _erc721.burnToken(msg.sender, id);
        _removeFromArray(msg.sender, id);
        delete _hungasById[id];
        delete _hungaToOwner[id];
        emit HungaDeleted(msg.sender, id);
    }






    function isSurge(HungaType hgt) internal returns (bool bi){//92izi
        if(hgt == HungaType.Radioactive) return true;
        if(hgt == HungaType.Disco) return PRNG() % 2 == 0 ? true : false;
        uint time = now % 1 days;
        if(time >= 6 hours && time <= 18 hours){
            if(hgt == HungaType.Solar) return true;
        }
        else if (hgt == HungaType.Lunar) return true;
        return false;
    }

    function getReward(uint hReward, uint hRisk, bool surge) internal returns (uint rwrd){
        uint _reward = hReward;
        uint _risk = hRisk;
        if(surge){
            _reward = hReward * 2;
            _risk = hRisk / 2;
        }
        uint rnd = PRNG();
        if(rnd%100 <= _risk) return _reward;
        else return 0;
    }

    function claimReward(uint id) public onlyOwnerOfhunga(id) returns (bool) {
        require(_hungasById[id].lastClaimed + 86400 <= now, "not 24h yet since last claim");

        uint _reward = _hungasById[id].reward;
        uint _risk = _hungasById[id].risk;
        uint _count = _hungasById[id].claimCount;

        uint _bananes = getReward(_reward, _risk, isSurge(_hungasById[id].hungaType));

        _hungasById[id].lastClaimed = now;
        _count++;
        _risk -= _risk * _count * _count * _reward / ((10-_count) * 100);
        
        _hungasById[id].risk = _risk;
        _hungasById[id].claimCount = _count;

        if(_bananes == 0){
            deadHunga(id);
            return false;
        }
        return _erc20.transferFromTrusted(msg.sender, _bananes);
    }








    function feedHunga(uint feededId, uint feederId) public  onlyOwnerOfhunga(feededId) onlyOwnerOfhunga(feederId) returns (bool) {
        require(_hungasById[feededId].hungaType == _hungasById[feederId].hungaType, "not same type");
        require(uint(_hungasById[feederId].hungaType) + 1 == uint(_hungasById[feededId].hungaType), "food hunga not rare enough");
        deadHunga(feederId);
        uint feed = _hungasById[feededId].feedToImprove - 1;
        if(feed == 0){
            feed = 3;

            uint rsk = _hungasById[feededId].risk;
            rsk += 3;
            if(rsk > 100) rsk = 100;
            _hungasById[feededId].risk = rsk;

            _hungasById[feededId].reward++;
        }
        emit HungaFed(msg.sender, _currentId);// emit fed
        return true;
    }







    function createAuction(uint id, uint initialPrice) public  onlyOwnerOfhunga(id) {
        require(!_auctionedhungas[id], "already auctioned");
        _auctionedhungas[id] = true;
        uint priceToBid = initialPrice.mul(uint(_hungasById[id].rank));
        _auctions[id] = Auction(msg.sender, address(0), now, initialPrice, priceToBid, 0);
        emit AuctionCreated(msg.sender, id);
    }

    function bidOnAuction(uint id, uint value) public  {
        require(msg.sender != _auctions[id].seller, "You bid on your own auction");
        require(_auctionedhungas[id], "not an auctioned hunga");
        require(value >= _auctions[id].priceToBid, "price not high enough");
        _transferTokenBid(msg.sender, id, value);
        _updateAuction(msg.sender, id, value);
        emit NewBid(msg.sender, id, value);
    }

    function _transferTokenBid(address newBidder, uint id, uint value) private {
        Auction memory auction = _auctions[id];
        if (auction.lastBidder != address(0)) {
            _erc20.transferFrom(auction.seller, auction.lastBidder, auction.bestOffer);
        } else {
            _erc20.transferFrom(newBidder, auction.seller, value);
        } 
    } 

    function _updateAuction(address newBidder, uint id, uint value) private {
        _auctions[id].lastBidder = newBidder;
        _auctions[id].priceToBid = _calculatepriceToBid(id);
        _auctions[id].bestOffer = value;
    }

    function _calculatepriceToBid(uint id) private view returns (uint) {
        return _auctions[id].priceToBid.mul(uint(_hungasById[id].rank));
    }

    function transferhunga(address receiver, uint id) public {
        _transferhunga(msg.sender, receiver, id);
    }

    // Auctioned hunga are locked
    function _transferhunga(address sender, address receiver, uint id) private onlyOwnerOfhunga(id) {
        require(_hungasById[id].id != 0, "not hunga");
        require(!_auctionedhungas[id], "auctioned hunga");
        _erc721.transferFrom(sender, receiver, id);
        _removeFromArray(sender, id);
        _hungasOfOwner[receiver].push(_hungasById[id]);
        _hungaToOwner[id] = receiver;
        emit HungaTransfered(sender, receiver, id);
    }

    function claimAuction(uint id) public onlyAuctionedhunga(id) {
        require(_auctions[id].lastBidder == msg.sender, "you are not the last bidder");
        require(_auctions[id].startDate + 2 days <= now, "2 days have not yet passed");
        _processRetrieveAuction(id);
        emit AuctionClaimed(msg.sender, id);
    }

    function _processRetrieveAuction(uint id) private {
        Auction storage auction = _auctions[id];
        if (auction.lastBidder != address(0)) {
            _transferhunga(auction.seller, auction.lastBidder, id);
            _auctionedhungas[id] = false;
            delete _auctions[id];
        }
    }
          
}