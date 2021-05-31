pragma solidity 0.8.0;

// for remix
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract SpaceOdyssey is ERC1155 {

    string public name;
    string public symbol;

    address private minter;
    uint256 public tokenID;

    mapping(uint256 => uint256) public totalSupply;

    mapping(uint256 => string) public tokenURI;

    // artist of flower and fee requested
    mapping(uint256 => address payable) public artist;

    event Minted(
        uint256 tokenId,
        uint256 supply,
        string tokenUri
    );

    event TokenBurn (
        uint256 tokenId,
        uint256 amountBurned,
        uint256 newTotalSupply
    );

    constructor() ERC1155("") {
        minter = msg.sender;
        name =  "Space Odyssey: Survival";
        symbol  = "SOS";
        tokenID = 0;
    }

    modifier onlyMinter {
        require(msg.sender == minter);
        _;
    }

    function mint(uint256 _supply, string memory _tokenURI, address payable _artist) public onlyMinter {
        require(_supply > 0);
        tokenID++;
        _mint(minter, tokenID, _supply, "");
        totalSupply[tokenID] += _supply;
        tokenURI[tokenID] = _tokenURI;
        artist[tokenID] = _artist;
        emit Minted( tokenID, _supply, _tokenURI );
    }

    function updateUri(uint256 _tokenID, string memory _tokenURI) public onlyMinter returns (bool) {
        tokenURI[_tokenID] = _tokenURI;
        return true;
    }

    function updateMinter(address newMinter) public onlyMinter returns (bool){
        minter = newMinter;
        return true;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount
    )
        public {
        safeTransferFrom( from, to, id, amount, "" );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    )
        public {
        safeBatchTransferFrom( from, to, ids, amounts, "" );
    }

    function burn(uint256 _tokenID, uint256 _amount) public onlyMinter {
        _burn(minter, _tokenID, _amount);
        totalSupply[_tokenID] -= _amount;

        emit TokenBurn ( _tokenID, _amount, totalSupply[_tokenID] );
    }
}
