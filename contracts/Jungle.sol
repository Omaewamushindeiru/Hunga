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

    event AuctionCreated(address indexed seller, uint tokenId);
    event AuctionClaimed(address indexed claimer, uint tokenId);
    event NewBid(address indexed bidder, uint tokenId, uint price);

    enum Rank {God, Legendary, Duke, Knight, Lame}
    enum HungaType {Solar, Lunar, Radioactive, Disco}

    mapping (uint => address) private _hungaToOwner;
    mapping (address => Hunga[]) private _hungasOfOwner;
    mapping (uint => Hunga) private _hungasById;
    mapping (uint => Auction) private _auctions;
    mapping (uint => bool) private _auctionedhungas;

    uint private _currentId;

    ERC721 private _erc721;
    ERC20 private _erc20;

    uint256 hungaValue;

    uint nonce;

    struct Hunga {
        uint id;

        Rank rank;
        HungaType hungaType;

        uint risk;
        uint reward;

        uint life;
        uint claimCount;
        uint lastClaimed;

        uint feedToImprove;
    }

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

    function getAuctioned(uint id) public view returns (address seller, address lastBidder, uint startDate, uint priceToBid, uint bestOffer) {
        require(_auctionedhungas[id], "not auctioned");
        Auction memory auction = _auctions[id];
        return (auction.seller, auction.lastBidder, auction.startDate, auction.priceToBid, auction.bestOffer);
    }

    function isAuctioned(uint id) public view returns (bool) {
        return _auctionedhungas[id];
    }


    modifier onlyOwnerOfhunga(uint id) {
        require(msg.sender == _hungaToOwner[id], "Not hunga owner");
        _;
    }


    modifier onlyAuctionedhunga(uint id) {
        require(_auctionedhungas[id], "not auctioned hunga");
        _;
    }





    function PRNG() public returns(uint) {
        nonce += 1;
        return uint(keccak256(abi.encodePacked(nonce, msg.sender, blockhash(block.number - 1))));
    }

    function discoverRank(uint lameRate, uint knightRate, uint dukeRate, uint rng) internal returns (Rank){
        require(lameRate + knightRate + dukeRate < 100, "impossible rates");
        require(lameRate > 0 && knightRate > 0 && dukeRate > 0, "rates can't be 0");
        if(rng%100 >= lameRate) return Rank.Lame;
        if(rng%100 >= lameRate + knightRate) return Rank.Knight;
        if(rng%100 >= lameRate + knightRate + dukeRate) return Rank.Duke;
        else return Rank.Legendary;
    }
    
    function discoverReward(Rank rnk, uint rng) internal returns(uint){
        int num = 5 - uint(rnk);
        return (num - 1) * 10 + rng % (num * 10);
    }

    function discoverHunga() public returns (bool) {
        require(_erc20.balanceOf(msg.sender) >= hungaValue, "not enough peels owned");
        _currentId++;

        uint rnd = PRNG();
        Rank rnk = discoverRank(71, 23, 6, rnd);
        HungaType hngtp = HungaType(nrd % 4);

        uint reward = 90;
        uint feed = (5-uint(rnk))*3;

        Hunga memory hunga = Hunga(_currentId, rnk, hngtp, 90, reward, 10, 0, now(), feed);

        _hungasOfOwner[msg.sender].push(hunga);
        _hungasById[_currentId] = hunga;
        _hungaToOwner[_currentId] = to;

        _erc721.mintToken(to, _currentId);

        return true;
    }





    function _removeFromArray(address owner, uint id) private {
        uint size = _hungasOfOwner[owner].length;
        for (uint index = 0; index < size; index++) {
            hunga storage hunga = _hungasOfOwner[owner][index];
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
        emit hungaDeleted(msg.sender, id);
    }






    function isSurge(Rank rnk) internal returns (bool bi){//92izi
        if(rnk == Rank.Radioactive) return true;
        if(rnk == Rank.Disco) return PRNG() % 2 == 0 ? true : false;
        uint time = now() % 86400;
        if(time >= 21600 && time <= 64800){
            if(rnk == Rank.Solar) return true;
        }
        else if (rnk == Rank.Lunar) return true;
        return false;
    }

    function reward(uint hReward, uint hRisk, bool surge) internal returns (uint rwrd){
        uint _reward = hReward;
        uint _risk = hRisk;
        if(surge){
            _reward = hReward * 2;
            _risk = risk / 2;
        }
        rnd = PRNG();
        if(rnd%100 <= _risk) return _reward;
        else return -1;
    }

    function claimReward(uint id) public onlyOwnerOfhunga(id) returns (bool) {
        uint _reward = _hungasById[id].reward;
        uint _risk = _hungasById[id].risk;
        Rank _rank = _hungasById[id].rank;

        uint _bananes = reward(_reward, _risk, isSurge(_rank));

        if(_bananes == -1){
            deadHunga(id);
            return false;
        }
        else return _erc20.transferFrom(_erc20.owner(), msg.sender, _bananes);
    }








    function breedhungas(uint senderId, uint targetId) public onlyBreeder() onlyOwnerOfhunga(senderId) returns (bool) {
        _preProcessBreeding(senderId, targetId);
        _processBreeding(msg.sender, senderId, targetId);
        emit NewBorn(msg.sender, _currentId);
        return true;
    }

    // Initially if a token is approved to a specific address means that this address can trade our token
    // We use this functionality to tell if a specific breeder can use our token in order to breed hungas
    function _preProcessBreeding(uint senderId, uint targetId) private view {
        require(_erc721.getApproved(targetId) == _hungaToOwner[senderId], "target hunga not approved");
        require(_sameRace(senderId, targetId), "not same race");
        require(_canBreed(senderId, targetId), "can't breed");
        require(_breedMaleAndFemale(senderId, targetId), "can't breed");
    }

    function _sameRace(uint id1, uint id2) private view returns (bool) {
        return (_hungasById[id1].race == _hungasById[id2].race);
    }

    function _canBreed(uint id1, uint id2) private view returns (bool) {
        return (_hungasById[id1].canBreed && _hungasById[id2].canBreed);
    }

    function _breedMaleAndFemale(uint id1, uint id2) private view returns (bool) {
        if ((_hungasById[id1].isMale) && (!_hungasById[id2].isMale)) return true;
        if ((!_hungasById[id1].isMale) && (_hungasById[id2].isMale)) return true;
        return false;
    }

    function _processBreeding(address to, uint senderId, uint targetId) private {
        hungaType race = _hungasById[senderId].race;
        Age age = Age.Young;
        Color color = _hungasById[senderId].color;
        uint rarity = _hungasById[senderId].rarity.add(_hungasById[targetId].rarity);
        bool isMale = _hungasById[targetId].isMale;
        bool canBreed = false;
        bool isVaccinated = _hungasById[senderId].isVaccinated;
        declarehunga(to, race, age, color, rarity, isMale, canBreed, isVaccinated);
    }

    function createAuction(uint id, uint initialPrice) public onlyBreeder() onlyOwnerOfhunga(id) {
        require(!_auctionedhungas[id], "already auctioned");
        _auctionedhungas[id] = true;
        uint priceToBid = initialPrice.mul(_hungasById[id].rarity);
        _auctions[id] = Auction(msg.sender, address(0), now, initialPrice, priceToBid, 0);
        emit AuctionCreated(msg.sender, id);
    }

    function bidOnAuction(uint id, uint value) public onlyBreeder() {
        require(msg.sender != _auctions[id].seller, "You bid on your own auction");
        require(_auctionedhungas[id], "not an auctioned hunga");
        require(value == _auctions[id].priceToBid, "not right price");
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
        return _auctions[id].priceToBid.mul(_hungasById[id].rarity);
    }

    function transferhunga(address receiver, uint id) public {
        _transferhunga(msg.sender, receiver, id);
    }

    // Auctioned hunga are locked
    function _transferhunga(address sender, address receiver, uint id) private onlyOwnerOfhunga(id) {
        require(isBreeder(receiver), "not a breeder");
        require(_hungasById[id].id != 0, "not hunga");
        require(!_auctionedhungas[id], "auctioned hunga");
        _erc721.transferFrom(sender, receiver, id);
        _removeFromArray(sender, id);
        _hungasOfOwner[receiver].push(_hungasById[id]);
        _hungaToOwner[id] = receiver;
        emit hungaTransfered(sender, receiver, id);
    }

    function claimAuction(uint id) public onlyBreeder() onlyAuctionedhunga(id) {
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