// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "../interfaces/IEncryptedERC20.sol";
// import "fhevm-contracts/contracts/utils/EncryptedErrors.sol";
import "fhevm/gateway/GatewayCaller.sol";

contract Tombola is GatewayCaller {
    struct Participant {
        eaddress eAddress;
        euint64 eRandomUsers;
    }
    struct LastError {
        euint8 error;
        uint timestamp;
    }

    eaddress private eWinner;
    address private winnerDecrypt;

    euint64 public eNumberWin;
    address public owner;
    uint64 public numberWinDecrypt;

    IEncryptedERC20 public token;
    uint256 public ticketPrice;
    uint256 public endTime = 0;
    uint64 participantsLength = 0;
    uint limitedTicket;
    bool isReclaim = false;
    bool isLimited = false;

    mapping(uint64 => Participant) randomUsers;
    event TicketPurchased(address indexed participant);
    event WinnerPicked(uint);

    euint8 internal NO_ERROR;
    euint8 internal ERROR;
    euint64 internal ZERO;

    mapping(address => LastError) public _lastErrors;
    event ErrorChanged(address indexed user);

    constructor(address _owner, address _tokenAddress) {
        owner = _owner;
        token = IEncryptedERC20(_tokenAddress);
        NO_ERROR = TFHE.asEuint8(0);
        ERROR = TFHE.asEuint8(1);
        ZERO = TFHE.asEuint64(0);
        eWinner = TFHE.asEaddress(address(0));
        eNumberWin = TFHE.asEuint64(0);

        TFHE.allow(ZERO, address(this));
        TFHE.allow(eNumberWin, address(this));
        TFHE.allow(eWinner, address(this));
        TFHE.allow(NO_ERROR, address(this));
        TFHE.allow(ERROR, address(this));
    }

    function requestAddress() internal {
        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(eWinner);
        Gateway.requestDecryption(cts, this.addressWinCallback.selector, 0, block.timestamp + 100, false);
    }

    function addressWinCallback(uint256 /*requestID*/, address decryptedInput) public onlyGateway returns (address) {
        winnerDecrypt = decryptedInput;
        return winnerDecrypt;
    }

    function numberWinCallback(uint256 /*requestID*/, uint64 decryptedInput) public onlyGateway returns (uint64) {
        numberWinDecrypt = decryptedInput;
        return numberWinDecrypt;
    }

    function requestNumberWin() internal {
        uint256[] memory cts = new uint256[](1);
        cts[0] = Gateway.toUint256(eWinner);
        Gateway.requestDecryption(cts, this.numberWinCallback.selector, 0, block.timestamp + 100, false);
    }

    function start(uint256 _ticketPrice, uint256 _duration, uint256 _limitedTicked) private {
        ticketPrice = _ticketPrice;
        endTime = block.timestamp + _duration;
        limitedTicket = _limitedTicked;
        if (limitedTicket > 0) {
            isLimited = true;
        }
    }

    function setLastError(euint8 error, address addr) private {
        _lastErrors[addr] = LastError(error, block.timestamp);
        emit ErrorChanged(addr);
    }

    function buyTicket(einput _eUser, einput _eAmount, bytes calldata inputProof) external {
        require(endTime > 0, "the tombola is not starting ");
        require(block.timestamp < endTime, "Tombola has ended");

        if (isLimited) {
            require(limitedTicket > 0, "Ticket sell is over");
        }

        euint64 eAmount = TFHE.asEuint64(_eAmount, inputProof);

        eaddress eUser = TFHE.asEaddress(_eUser, inputProof);

        setLastError(TFHE.select(TFHE.gt(eAmount, ZERO), NO_ERROR, ERROR), msg.sender);

        euint64 randomNumber = getRandom();
        TFHE.allowTransient(randomNumber, address(this));
        TFHE.allow(randomNumber, msg.sender);

        randomUsers[participantsLength] = Participant(eUser, randomNumber);

        require(
            token.transferFrom(msg.sender, address(this), _eAmount, inputProof),
            "echec transferFrom deposit erc20 to smart contract"
        );

        participantsLength += 1;

        emit TicketPurchased(msg.sender);
    }

    function getRandom() public returns (euint64) {
        return TFHE.randEuint64();
    }

    function selectWinner(uint32 i, euint64 minDifference, euint64 randomNumber) internal {
        require(TFHE.isSenderAllowed(minDifference), "The caller is not authorized to access this secret.");
        require(TFHE.isSenderAllowed(randomNumber), "The caller is not authorized to access this secret.");

        euint64 eRandomNumberUser = randomUsers[i].eRandomUsers;
        eaddress eAddressUser = randomUsers[i].eAddress;

        euint64 difference = TFHE.sub(eRandomNumberUser, randomNumber);
        ebool isSmaller = TFHE.lt(difference, minDifference);

        minDifference = TFHE.select(isSmaller, difference, minDifference);
        eWinner = TFHE.select(isSmaller, eAddressUser, eWinner);
    }

    function getBalanceContract() public view returns (euint64) {
        return token.balanceOf(address(this));
    }

    function pickWinner() external {
        require(!isReclaim, "Tombola is over");
        require(block.timestamp >= endTime, "Tombola is still ongoing");
        require(participantsLength > 0, "No participants");
        //require(token.balanceOf(address(this)) > 0, "no token on smart contract");
        //euint64 eAmountWinner = TFHE.select(TFHE.gt(token.balanceOf(address(this)), ZERO));
        ebool eIsNotZero = TFHE.gt(token.balanceOf(address(this)), ZERO);

        euint64 eBalance = token.balanceOf(address(this));
        TFHE.allowTransient(eBalance, address(this));

        euint64 eAmountWinner = TFHE.select(eIsNotZero, eBalance, ZERO);

        setLastError(TFHE.select(eIsNotZero, NO_ERROR, ERROR), msg.sender);

        euint64 randomNumber = getRandom();
        euint64 minDifference = TFHE.sub(randomNumber, randomNumber);

        TFHE.allowTransient(minDifference, address(this));

        for (uint32 i = 0; i < participantsLength; i++) {
            selectWinner(i, minDifference, randomNumber);
        }
        requestAddress();
        requestNumberWin();
        isReclaim = true;
        require(token.transfer(winnerDecrypt, eAmountWinner), "echec transfer deposit erc20 to smart contract");

        emit WinnerPicked(block.timestamp);
    }
}
