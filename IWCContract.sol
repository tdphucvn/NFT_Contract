// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";
import "https://github.com/1001-digital/erc721-extensions/blob/main/contracts/RandomlyAssigned.sol";

contract IWCContract is ERC721, Ownable, RandomlyAssigned {
    using Strings for uint256;
    // using Counters for Counters.Counter;

    // Counters.Counter private supply;

    string public uriPrefix = "";
    string public uriSuffix = ".json";
    // string public hiddenMetadataUri; // can display a placeholder, until the NFT is revealed

    uint256 public cost = 1 ether; // public mint cost
    uint256 public maxSupply; // total number of NFTs, this will change, depending on the final amount
    uint256 public maxMintAmountPerTx = 1;
    uint256 public activeRound = 1; // current mint round
    uint256 public startTime; // start time of the round
    uint256 public endTime; // end time of the round

    bool public paused = true;
    bool public revealed = false;

    mapping(address => bool) private hasMinted; // check if the person has already minted
    mapping(address => bool) private firstRoundWhitelist; // first round whitelist
    mapping(address => bool) private secondRoundWhitelist; // second round whitelist

    constructor(
        string _name,
        string _symbol,
        uint256 _maxSupply
    ) ERC721(_name, _symbol) RandomlyAssigned(_maxSupply, 1) {
        // setHiddenMetadataUri("ipfs://__CID__/hidden.json");
        maxSupply = _maxSupply;
    }

    modifier mintCompliance(address _receiver) {
        require(tokenCount() + 1 <= totalSupply(), "Max supply exceeded!");
        require(
            availableTokenCount() - 1 >= 0,
            "You can't mint more than available token count"
        );
        require(now() > startTime, "Minting hasn't started yet");
        require(now() < endTime, "Minting has ended");
        if (round = 1) {
            require(
                firstRoundWhitelist[_receiver],
                "Address is not on the whitelist"
            );
        } else {
            require(
                firstRoundWhitelist[_receiver],
                "Address is not on the whitelist"
            );
        }
        _;
    }

    modifier maxAmount(address _receiver) {
        require(!hasMinted[_receiver], "One person can mint only 1 NFT");
        _;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply();
    }

    function mint()
        public
        payable
        mintCompliance(msg.sender)
        maxAmount(msg.sender)
    {
        require(!paused, "The contract is paused!");
        require(msg.value >= cost, "Insufficient funds!");

        uint256 id = nextToken();
        _safeMint(msg.sender, id);
        hasMinted[msg.sender] = true;
        currentSupply++;
    }

    function mintForAddress(address _receiver)
        public
        mintCompliance(_receiver)
        maxAmount(_receiver)
        onlyOwner
    {
        uint256 id = nextToken();
        _safeMint(_receiver, id);
        hasMinted[_receiver] = true;
        currentSupply++;
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (
            ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply
        ) {
            address currentTokenOwner = ownerOf(currentTokenId);

            if (currentTokenOwner == _owner) {
                ownedTokenIds[ownedTokenIndex] = currentTokenId;

                ownedTokenIndex++;
            }

            currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        _tokenId.toString(),
                        uriSuffix
                    )
                )
                : "";
    }

    // function setRevealed(bool _state) public onlyOwner {
    //     revealed = _state;
    // }

    function setCost(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx)
        public
        onlyOwner
    {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri)
        public
        onlyOwner
    {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setActiveRound(uint256 _round) public onlyOwner {
        require(_round > 0 && _round < 3, "Invalid mint round");
        activeRound = _round;
    }

    function setWhitelist(uint256 _round, address[] _whitelist)
        public
        onlyOwner
    {
        require(_whitelist.length > 0, "The whitelist is empty");
        if (_round = 1) {
            for (uint256 i = 0; i < _whitelist.length; i++) {
                firstRoundWhitelist[_whitelist[i]] = true;
            }
        } else {
            for (uint256 i = 0; i < _whitelist.length; i++) {
                secondRoundWhitelist[_whitelist[i]] = true;
            }
        }
    }

    function setTime(uint256 _startTime, uint256 _endTime) public onlyOwner {
        require(_startTime < _endTime, "Invalid date");
        startTime = _startTime;
        endTime = _endTime;
    }

    function withdraw() public onlyOwner {
        // This will transfer the remaining contract balance to the owner.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }
}
