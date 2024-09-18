// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SimpleERC721 {
    // Token name
    string public name = "SimpleERC721";
    // Token symbol
    string public symbol = "SERC721";

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Token counter
    uint256 private _tokenIdCounter;

    // Event for token transfer
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    // Event for approval
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    // Event for approval for all
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Returns the number of tokens in owner's account
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Address zero is not a valid owner");
        return _balances[owner];
    }

    // Returns the owner of the tokenId token
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token ID does not exist");
        return owner;
    }

    // Approves another address to transfer the given token ID
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender), "Caller is not owner nor approved for all");

        _approve(to, tokenId);
    }

    // Gets the approved address for a token ID, or zero if no address set
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_owners[tokenId] != address(0), "Token ID does not exist");
        return _tokenApprovals[tokenId];
    }

    // Approves or removes an operator for the caller
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // Tells whether an operator is approved by a given owner
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // Transfers ownership of a given token ID to another address
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    // Internal function to safely transfer a given token ID to another address
    function _transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Transfer of token that is not owned");
        require(to != address(0), "Transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // Internal function to invoke {IERC721Receiver-onERC721Received} on a target address
    function _approve(address to, uint256 tokenId) internal {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    // Returns whether the given spender can transfer a given token ID
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_owners[tokenId] != address(0), "Token ID does not exist");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    // Mints a new token
    function mint(address to) public {
        require(to != address(0), "Mint to the zero address");

        _tokenIdCounter += 1;
        uint256 tokenId = _tokenIdCounter;

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
}
