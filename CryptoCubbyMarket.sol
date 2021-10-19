pragma solidity 0.8.7;


// imports are for remix
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract CryptoCubbiesMarket is ERC721Holder, ReentrancyGuard {
    using Counters for Counters.Counter;
    // using Strings for uint256;
    using SafeERC20 for IERC20;


    string public name;
    Counters.Counter private _nftCount;
    Counters.Counter private _nftsSold;
    address public admin;

    address public artist;

    uint256 public artistFee;
    uint256 public ccashFee;

    address public nftContract;
    IERC20 public ccash;

    uint256 private largestTokenID;


    mapping(uint256 => NFT) public nft;


    struct NFT {
        uint256 nftMarketID;
        uint256 tokenID;
        uint256 price;
        uint256 coinopolisFee;
        address owner;
        string tokenURI;
        bool listed;
    }

    event NFTAdded(
        uint256 nftMarketID,
        uint256 tokenID,
        string tokenURI,
        uint256 price
    );

    event NFTPurchased(
        uint256 nftMarketID,
        uint256 tokenID,
        string tokenURI,
        uint256 price
    );

    event PriceUpdated(
        uint256 nftMarketID,
        uint256 tokenID,
        uint256 newPrice
    );

    event NFTRemoved(
        uint256 nftMarketID,
        uint256 tokenID
    );

    event NFTRelisted(
        uint256 nftMarketID,
        uint256 tokenID,
        string tokenURI,
        uint256 price
    );



    constructor() {
        name = "Crypto Cubbies Market";
        admin = msg.sender;
        ccash = IERC20(0x20378cc7835ec12C1DBcCfdF76F0318b516768d7);
        nftContract = address(0x715CC9E956212caF806FdaD11175B029Da733d52);
        ccashFee = 500000000000000000000;
        artistFee = 1000;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "you must be the admin");
        _;
    }

    function updateAdmin(address _newAdmin) public onlyAdmin returns (bool){
        admin = _newAdmin;
        return true;
    }

    function updateArtist(address _newArtist) public onlyAdmin returns (bool){
        artist = _newArtist;
        return true;
    }

    function calcFee(uint256 _amountValue, uint256 _fee) internal pure returns(uint256) {
        require((_amountValue / 10000) * 10000 == _amountValue, "too small");
        _amountValue = _amountValue;
        uint256 fee = _amountValue * _fee / 10000;
        return fee;
    }

    function createNFT(uint256 _tokenID, uint256 _price) public nonReentrant {
        require(!_tokenExists(_tokenID), "token ID already exist in Market IDs. Please use relistNFT function.");
        require(_tokenID > 0, "token ID has to be greater than zero");
        require(_price > 0, "price must be greater than zero");
        require(ERC721(nftContract).ownerOf(_tokenID) == msg.sender, "you are not the owner");

        if(_tokenID > largestTokenID) {
            updateLargestTokenID(_tokenID);
        }

        _nftCount.increment();

        uint256 _coinopolisFee = 150;
        string memory _tokenURI = ERC721(nftContract).tokenURI(_tokenID);

        address _owner = payable(msg.sender);
        nft[_tokenID] = NFT(_tokenID, _tokenID, _price, _coinopolisFee, _owner, _tokenURI, true);

        ERC721(nftContract).safeTransferFrom(msg.sender, address(this), _tokenID);

        emit NFTAdded(_tokenID, _tokenID, _tokenURI,_price);
    }

    function relistNFT(uint256 _tokenID, uint256 _price) public nonReentrant {
        require(_tokenExists(_tokenID), "token ID doesn't exist in Market IDs.");
        require(_tokenID > 0, "token ID must be great than zero.");
        require(_price > 0, "price must be greater than 0");
        require(ERC721(nftContract).ownerOf(_tokenID) == msg.sender, "you are not the owner");


        string memory _tokenURI = ERC721(nftContract).tokenURI(_tokenID);


        NFT memory _nft = nft[_tokenID];

        _nft.price = _price;
        _nft.coinopolisFee = 200;
        _nft.owner = payable(msg.sender);
        _nft.tokenURI = _tokenURI;
        _nft.listed = true;

        nft[_tokenID] = _nft;

        ERC721(nftContract).safeTransferFrom(msg.sender, address(this), _tokenID);

        emit NFTRelisted(_tokenID, _tokenID, _tokenURI,_price);
    }

    function purchaseNFT(uint256 _nftMarketID) public payable nonReentrant {
        require(_nftMarketID > 0, "market ID must be greater that zero.");
        require( ccash.balanceOf(msg.sender) >= ccashFee, "you do not have enough $CCAH to perform this transaction.");

        NFT memory _nft = nft[_nftMarketID];

        require(_tokenExists(_nft.tokenID), "token ID doesn't exist in Market IDs.");
        require(msg.value >= _nft.price, "purchase value too low...");
        require(_nft.listed, "NFT already sold...");


        uint256 _coinopolisFee = calcFee(msg.value, _nft.coinopolisFee);
        uint256 _artistFee = calcFee(msg.value, artistFee);
        uint256 _fees = _coinopolisFee + _artistFee;
        uint256 _sellValue = msg.value - _fees;


        payable(admin).transfer(_coinopolisFee);
        payable(artist).transfer(_artistFee);
        payable(_nft.owner).transfer(_sellValue);

        ccash.transferFrom(address(msg.sender), address(admin), ccashFee);

        ERC721(nftContract).safeTransferFrom(address(this), msg.sender, _nft.tokenID);

        _nft.listed = false;

        nft[_nftMarketID] = _nft;
        _nftsSold.increment();

        emit NFTPurchased(_nftMarketID, _nft.tokenID, _nft.tokenURI, _nft.price);

    }

    function updatePrice(uint256 _nftMarketID, uint256 _newPrice) public {
        require(_nftMarketID > 0, "market ID must be greater that zero.");
        require(_tokenExists(nft[_nftMarketID].tokenID), "token ID doesn't exist in Market IDs.");
        require(_newPrice > 0, "price must be greater than zero");
        require(msg.sender == nft[_nftMarketID].owner, "you must be owner");

        NFT memory _nft = nft[_nftMarketID];
        _nft.price = _newPrice;
        nft[_nftMarketID] = _nft;

        emit PriceUpdated( _nftMarketID, nft[_nftMarketID].tokenID, nft[_nftMarketID].price );
    }

    function removeToken(uint256 _nftMarketID) public nonReentrant returns (bool) {
        require(_nftMarketID > 0, "market ID must be greater that zero.");
        require(msg.sender == nft[_nftMarketID].owner, "you must be owner");

        NFT memory _nft = nft[_nftMarketID];

        ERC721(nftContract).safeTransferFrom(address(this), _nft.owner, _nft.tokenID);

        _nft.listed = false;

        nft[_nftMarketID] = _nft;

        return true;
    }

    function _tokenExists(uint256 _tokenID) public view returns(bool) {
        bool _existingToken = false;
        if(nft[_tokenID].tokenID == _tokenID) {
            _existingToken = true;
        }
        return _existingToken;
    }

    function updateTokenURI(uint256 _tokenID) public nonReentrant returns(bool) {
        require(_tokenExists(_tokenID), "token does not exist");
        nft[_tokenID].tokenURI = ERC721(nftContract).tokenURI(_tokenID);
        return true;
    }

    function fetchMarketNFTs() public view returns (NFT[] memory) {
        uint256 _latestId = _nftCount.current();
        uint256 _currentIndex = 0;
        NFT[] memory _result = new NFT[](_latestId);
        for(uint256 i = 0; i < largestTokenID; i++) {
            uint256 _tokenID = i + 1;
            if(_tokenExists(_tokenID)) {
                NFT memory _currentNFT = nft[_tokenID];
                _result[_currentIndex] = _currentNFT;
                _currentIndex++;
            }
        }
        return _result;
    }

    function getCoinopolisFee(uint256 _nftMarketID) public view returns(uint256) {
        uint256 _coinopolisFee = nft[_nftMarketID].coinopolisFee;
        return _coinopolisFee;
    }

    function updateCoinopolisFee(uint256 _nftMarketID, uint256 _newCoinopolisFee) public onlyAdmin() returns(uint256) {
        nft[_nftMarketID].coinopolisFee = _newCoinopolisFee;
        return nft[_nftMarketID].coinopolisFee;
    }

    function updateArtistFee(uint256 _newArtistFee) public onlyAdmin() returns(uint256) {
        artistFee = _newArtistFee;
        return artistFee;
    }

    function updateNFTContract(address _newContract) public onlyAdmin() returns(address) {
        nftContract = _newContract;
        return nftContract;
    }

    function updateCCASH(address _newContract) public onlyAdmin() returns(bool) {
        ccash = IERC20(_newContract);
        return true;
    }

    function nftsListedCount() public view returns(uint256) {
        return _nftCount.current();
    }

    function nftsSoldCount() public view returns(uint256) {
        return _nftsSold.current();
    }

    function updateLargestTokenID(uint256 _tokenID) internal {
        largestTokenID = _tokenID;
    }
}
