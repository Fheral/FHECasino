// SPDX-License-Identifier: BSD-3-Clause-Clear

pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "fhevm/gateway/GatewayCaller.sol";
import "./interfaces/IEncryptedERC20.sol";

contract PrivatePool {
    struct LastError {
        euint8 error;
        uint timestamp;
    }

    euint8 internal NO_ERROR;
    euint8 internal ERROR;
    euint64 internal ZERO;

    mapping(address => LastError) public _lastErrors;

    IEncryptedERC20 public token; // L'adresse du token ERC-20
    mapping(address => euint64) public eBalances; // Mapping pour suivre les dépôts de chaque utilisateur
    event ErrorChanged(address indexed user);

    constructor(address _tokenAddress) {
        token = IEncryptedERC20(_tokenAddress); // Initialiser l'adresse du token ERC-20
        NO_ERROR = TFHE.asEuint8(0);
        ERROR = TFHE.asEuint8(1);
        ZERO = TFHE.asEuint64(0);

        //TFHE.allow(eBalances, address(this));
    }

    function setLastError(euint8 error, address addr) private {
        _lastErrors[addr] = LastError(error, block.timestamp);
        emit ErrorChanged(addr);
    }

    // Fonction pour déposer des tokens dans la pool
    function deposit(einput _eAmount, bytes calldata inputProof) external {
        euint64 eAmount = TFHE.asEuint64(_eAmount, inputProof);

        ebool eIsNotZero = TFHE.gt(eAmount, ZERO);

        setLastError(TFHE.select(eIsNotZero, NO_ERROR, ERROR), msg.sender);

        eBalances[msg.sender] = TFHE.add(eBalances[msg.sender], TFHE.select(eIsNotZero, eAmount, ZERO));
    }

    // Fonction pour envoyer des tokens à une adresse spécifique
    function withdraw(einput _eAmount, bytes calldata inputProof) external {
        euint64 eAmount = TFHE.asEuint64(_eAmount, inputProof);

        ebool eIsNotZero = TFHE.gt(eAmount, ZERO);
        ebool eBalanceNotZero = TFHE.gt(eBalances[msg.sender], ZERO);

        setLastError(TFHE.select(eIsNotZero, NO_ERROR, ERROR), msg.sender);
        setLastError(TFHE.select(eBalanceNotZero, NO_ERROR, ERROR), msg.sender);

        //ebool eTwoCondition = TFHE.select(NO_ERROR, a, b);

        eBalances[msg.sender] = TFHE.sub(
            TFHE.select(eBalanceNotZero, eBalances[msg.sender], ZERO),
            TFHE.select(eIsNotZero, eAmount, ZERO)
        );
    }

    // Fonction pour consulter le solde de l'utilisateur dans la pool
    function getUserBalance() external view returns (uint256) {
        //  return balances[msg.sender];
    }
}
