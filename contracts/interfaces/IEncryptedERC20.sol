// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";

interface IEncryptedERC20 {
    // Events
    event Transfer(address indexed from, address indexed to);
    event Approval(address indexed owner, address indexed spender);
    event Mint(address indexed to, uint64 amount);

    // Functions
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint64);

    function mint(uint64 mintedAmount) external;

    function transfer(address to, einput encryptedAmount, bytes calldata inputProof) external returns (bool);
    function transfer(address to, euint64 amount) external returns (bool);

    function balanceOf(address wallet) external view returns (euint64);

    function approve(address spender, einput encryptedAmount, bytes calldata inputProof) external returns (bool);
    function approve(address spender, euint64 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (euint64);

    function transferFrom(
        address from,
        address to,
        einput encryptedAmount,
        bytes calldata inputProof
    ) external returns (bool);
    function transferFrom(address from, address to, euint64 amount) external returns (bool);
}
