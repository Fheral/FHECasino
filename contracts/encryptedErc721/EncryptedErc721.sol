// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EncryptedErc721 is ERC721Enumerable {
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name, string memory symbol) ERC721("GeoSpace", "GSP") {}

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function mint(address to, uint256 tokenId, string memory _tokenURI) external {
        _mint(to, tokenId);
        _setTokenURI(tokenId, _tokenURI);
    }
}
