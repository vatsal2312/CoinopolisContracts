
pragma solidity 0.8.0;


import "./SpaceOdyssey.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract SpaceOdysseyMarket is ERC1155Holder {
    using SafeERC20 for IERC20;


    string public name;
    uint256 public productCount = 0;
    address public admin;
    SpaceOdyssey public spaceOdyssey;
    IERC20 public ccash;

    mapping(uint256 => Product) public products;

    struct Product {
        uint256 id;
        uint256 tokenID;
        uint256 tokenAmount;
        uint256 price;
        address payable artist;
        uint256 artistFee;
        bool purchased;
    }

    event ProductCreated(
        uint256 id,
        uint256 tokenID,
        uint256 tokenAmount,
        uint256 price,
        address payable artist,
        bool purchased
    );

    event ProductPurchased(
        uint256 id,
        uint256 tokenID,
        uint256 tokenAmount,
        uint256 price,
        address payable artist,
        bool purchased
    );

    event PriceUpdated(
        uint256 _id,
        uint256 tokenID,
        uint256 newPrice
    );

    event AmountIncrease(
        uint256 id,
        uint256 tokenId,
        uint256 tokenAmount
    );

    constructor(SpaceOdyssey _spaceOdyssey, IERC20 _ccash) {
        name = "Coinopolis Space Odyssey Market";
        admin = msg.sender;
        spaceOdyssey = _spaceOdyssey;
        ccash = _ccash;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "you must be the admin");
        _;
    }
    function updateAdmin(address payable newAdmin) public onlyAdmin returns (bool){
        admin = newAdmin;
        return true;
    }

    function updateArtistFee(uint256 _id, uint256 _artistFee) public onlyAdmin returns(bool) {
        products[_id].artistFee = _artistFee;
        return true;
    }

    function calcFee(uint256 _amount, uint256 _fee) internal pure returns(uint256) {
        require((_amount / 10000) * 10000 == _amount, "too small");
        _amount = _amount;
        uint256 fee = _amount * _fee / 10000;
        return fee;
    }

    function calcQuantityPrice(uint256 _amount, uint256 _price) internal pure returns(uint256) {
        require((_amount / 10000) * 10000 == _amount, "too small");
        _amount = _amount;
        uint256 _quantPrice = _amount * _price;
        return _quantPrice;
    }

    function createProduct(uint256 _tokenID, uint256 _tokenAmount, uint256 _price, uint256 _artistFee) public onlyAdmin {
        require(_tokenID > 0);
        require(_tokenAmount > 0);
        require(_price > 0);

        productCount++;

        address payable _artist = spaceOdyssey.artist(_tokenID);

        products[productCount] = Product(productCount, _tokenID,_tokenAmount, _price,  _artist, _artistFee, false);
        spaceOdyssey.safeTransferFrom(msg.sender, address(this), _tokenID, _tokenAmount);
        emit ProductCreated(productCount, _tokenID, _tokenAmount, _price, _artist, false);
    }

    function getBalanceOf(address _address) internal returns(uint256) {
        return ccash.balanceOf(_address);
    }

    function purchaseProduct(uint256 _id, uint256 _amount) public payable {
        Product memory _product = products[_id];
        require(_product.id > 0 && _product.id <= productCount);
        require( getBalanceOf(msg.sender) >= _product.price );
        require(_amount > 0 );
        require(!_product.purchased);

        uint256 _artistFee = calcFee(_amount, products[_id].artistFee);
        uint256 sellerValue = _amount - _artistFee;

        _product.tokenAmount -= 1;


        if (_product.tokenAmount <=0) {
            _product.purchased = true;
        }

        products[_id] = _product;

        uint256 _tokenID = products[_id].tokenID;
        spaceOdyssey.safeTransferFrom(address(this), msg.sender, _tokenID, 1);

        ccash.transferFrom(address(msg.sender), address(admin), sellerValue);

        ccash.transferFrom(address(msg.sender), products[_id].artist, _artistFee);

        emit ProductPurchased(_id, _product.tokenID, 1, _product.price,  _product.artist, true);
    }

    function addTokens(uint256 _id, uint256 _amount) public onlyAdmin {
        Product memory _product = products[_id];
        require(_amount > 0);
        uint256 senderBalanceOf = spaceOdyssey.balanceOf(msg.sender, _product.tokenID);
        require(senderBalanceOf > 0 && senderBalanceOf >= _amount);
        spaceOdyssey.safeTransferFrom(msg.sender, address(this), _product.tokenID, _amount);
        _product.tokenAmount += _amount;
        _product.purchased = false;
        products[_id] = _product;
        
        emit AmountIncrease( _id, products[_id].tokenID, _amount );
    }

    function updatePrice(uint256 _id, uint256 _newPrice) public onlyAdmin {
        Product memory _product = products[_id];
        require(_newPrice > 0);

        _product.price = _newPrice;
        products[_id] = _product;

        emit PriceUpdated( _id, products[_id].tokenID, products[_id].price );
    }

    function removeToken(uint256 _id) public payable onlyAdmin returns (bool) {
        Product memory _product = products[_id];

        spaceOdyssey.safeTransferFrom(address(this), admin, _product.tokenID, _product.tokenAmount);

        _product.tokenAmount = 0;

        _product.purchased = true;

        products[_id] = _product;

        return true;
    }

    function getArtistFee(uint256 _id) public view returns(uint256) {
        uint256 _artistFee = products[_id].artistFee;
        return _artistFee;
    }
}
