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
    euint8 internal NOT_ENOUGH_FOUND;
    euint64 internal ZERO;
    euint64 public eBalanceTotal;

    mapping(address => LastError) public _lastErrors;

    IEncryptedERC20 public token;
    mapping(address => euint64) public eBalances;

    event ErrorChanged(address indexed user);

    constructor(address _tokenAddress) {
        token = IEncryptedERC20(_tokenAddress);
        NO_ERROR = TFHE.asEuint8(0);
        NOT_ENOUGH_FOUND = TFHE.asEuint8(1);
        ZERO = TFHE.asEuint64(0);
        eBalanceTotal = TFHE.asEuint64(0);
        TFHE.allow(ZERO, address(this));
        TFHE.allow(eBalanceTotal, address(this));
        TFHE.allow(NO_ERROR, address(this));
        TFHE.allow(NOT_ENOUGH_FOUND, address(this));
    }

    function setLastError(euint8 error, address addr) private {
        _lastErrors[addr] = LastError(error, block.timestamp);
        emit ErrorChanged(addr);
    }

    function deposit(einput _eAmount, bytes calldata inputProof) external {
        euint64 eAmount = TFHE.asEuint64(_eAmount, inputProof);
        TFHE.allow(eAmount, address(this));

        ebool eIsNotZero = TFHE.gt(eAmount, ZERO);
        setLastError(TFHE.select(eIsNotZero, NO_ERROR, NOT_ENOUGH_FOUND), msg.sender);

        euint64 eAddingBalance = TFHE.add(eBalances[msg.sender], TFHE.select(eIsNotZero, eAmount, ZERO));
        TFHE.allow(eAddingBalance, address(this));

        eBalances[msg.sender] = TFHE.add(eBalances[msg.sender], eAddingBalance);
        TFHE.add(eBalanceTotal, eAddingBalance);

        require(
            token.transferFrom(msg.sender, address(this), _eAmount, inputProof),
            "echec transferFrom deposit erc20 to smart coontract"
        );
        //TFHE.allow(eAmount, msg.sender);

        // require(token.transferFrom(msg.sender, address(this), eAmount), "echec transferFrom");
    }

    function testDeposit(einput _eAmount, bytes calldata inputProof) external {
        euint64 eAmount = TFHE.asEuint64(_eAmount, inputProof);
        TFHE.allow(eAmount, address(this));
        ebool eIsNotZero = TFHE.gt(eAmount, ZERO);
        setLastError(TFHE.select(eIsNotZero, NO_ERROR, NOT_ENOUGH_FOUND), msg.sender);
        euint64 eAddingBalance = TFHE.add(eBalances[msg.sender], TFHE.select(eIsNotZero, eAmount, ZERO));
        TFHE.allow(eAddingBalance, address(this));
        eBalances[msg.sender] = TFHE.add(eBalances[msg.sender], eAddingBalance);
        TFHE.add(eBalanceTotal, eAddingBalance);

        // eBalances[msg.sender] = TFHE.add(eBalances[msg.sender], TFHE.select(eIsNotZero, eAmount, ZERO));
    }

    // Fonction pour envoyer des tokens à une adresse spécifique
    function withdraw(einput _eAmount, bytes calldata inputProof) external {
        euint64 eAmount = TFHE.asEuint64(_eAmount, inputProof);

        TFHE.allow(eAmount, address(this));

        ebool eIsNotZero = TFHE.gt(eAmount, ZERO);
        ebool eBalanceNotZero = TFHE.gt(eBalances[msg.sender], ZERO);

        setLastError(TFHE.select(eIsNotZero, NO_ERROR, NOT_ENOUGH_FOUND), msg.sender);
        setLastError(TFHE.select(eBalanceNotZero, NO_ERROR, NOT_ENOUGH_FOUND), msg.sender);

        euint64 eSubBalance = TFHE.sub(
            TFHE.select(eBalanceNotZero, eBalances[msg.sender], ZERO),
            TFHE.select(eIsNotZero, eAmount, ZERO)
        );

        /*  eBalances[msg.sender] = TFHE.sub(
            TFHE.select(eBalanceNotZero, eBalances[msg.sender], ZERO),
            TFHE.select(eIsNotZero, eAmount, ZERO)
        );*/
        TFHE.allow(eSubBalance, address(this));
        TFHE.sub(eBalanceTotal, eSubBalance);
    }

    function getBalanceDepositUser() public view returns (euint64) {
        return eBalances[msg.sender];
    }
}
