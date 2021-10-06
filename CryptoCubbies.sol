// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CryptoCubbies is ERC721, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using SafeERC20 for IERC20;

    Counters.Counter _tokenIds;
    uint256 public mintNumber;
    address payable public admin;
    mapping(uint256 => string) _tokenURIs;
    bool public mintingCompleted;
    bool public publicMintingActive;
    uint256 public maticMintFee;
    uint256 public ccashMintFee;
    IERC20 public ccash;
    
    struct RenderToken {
        uint256 id;
        string uri;
    }

    constructor() ERC721("CryptoCubbies", "CC") {
        admin = payable(msg.sender);
        mintNumber = 111;
        mintingCompleted = false;
        publicMintingActive = false;
        maticMintFee = 10000000000000000000;
        ccashMintFee = 1000000000000000000000;
        ccash = IERC20(0xEDB8e1A3697d92C2E416dcae12394026440aB3DC);
    }
    
    // modifier to check if caller is admin
    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not admin");
        _;
    }
    
    function updateMintNumber(uint256 _newMintNumber) public onlyAdmin() returns(uint256) {
        mintNumber = _newMintNumber;
        return mintNumber;
    }
    
    function updateMaticMintFee(uint256 _newMaticMintFee) public onlyAdmin() returns(uint256) {
        maticMintFee = _newMaticMintFee;
        return maticMintFee;
    }
    
    function updateCcashMintFee(uint256 _newCcashMintFee) public onlyAdmin() returns(uint256) {
        ccashMintFee = _newCcashMintFee;
        return ccashMintFee;
    }
    
    function togglePublicMinting() public onlyAdmin() returns(bool) {
        publicMintingActive = !publicMintingActive;
        return publicMintingActive;
    }
    
    function endMinting(bool ending) public onlyAdmin() returns(bool) {
        if(ending) {
            mintingCompleted = true;
        }
        return mintingCompleted;
    }
    
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyAdmin() {
        _tokenURIs[tokenId] = _tokenURI;
    }
    
    function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
        require(_exists(_tokenId), "Token ID not found...");
        string memory _tokenURI = _tokenURIs[_tokenId];
        return _tokenURI;
    }
    
    function getAllTokens() public view returns(RenderToken[] memory) {
        uint256 latestId = _tokenIds.current();
        latestId += 1;
        uint256 counter = 0;
        RenderToken[] memory result = new RenderToken[](latestId);
        for(uint256 i = 0; i < latestId; i++) {
            if(_exists(counter)) {
                string memory uri = tokenURI(counter);
                result[counter] = RenderToken(counter, uri);
            }
            counter++;
        }
        return result;
    }
    
    function totalSupply() public view returns(uint256) {
        return _tokenIds.current();
    }
    
    function mint(address recipient) public onlyAdmin() returns(uint256) {
        require(!mintingCompleted, "minting has finished.");
        _tokenIds.increment();
        require(_tokenIds.current() <= mintNumber, "Minting is currently completed....");
        uint256 newId = _tokenIds.current();
        _mint(recipient, newId);
        return newId;
    }
    
    function publicMint() payable public returns(uint256) {
        address recipient = msg.sender;
        require(!mintingCompleted, "minting has finished.");
        require(publicMintingActive, "current minting has finished.");
        require(msg.value >= maticMintFee, "must pay the mint fees.");
        require(ccash.balanceOf(msg.sender) >= ccashMintFee, "need more $CCASH to pay mint fees");
        _tokenIds.increment();
        require(_tokenIds.current() <= mintNumber, "Minting is currently completed....");
        
        uint256 newId = _tokenIds.current();
        _mint(recipient, newId);
        admin.transfer(msg.value);
        ccash.transferFrom(recipient, admin, ccashMintFee);
        return newId;
    }
}
