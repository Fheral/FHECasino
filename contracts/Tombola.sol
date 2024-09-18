// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";
import "./interfaces/IEncryptedERC20.sol";
// import "fhevm-contracts/contracts/utils/EncryptedErrors.sol";

contract Tombola {
    struct Participant {
        eaddress eAddress;
        euint64 eRandomUsers;
    }

    address public owner;
    eaddress private winner;

    IEncryptedERC20 public token;
    uint256 public ticketPrice;
    uint256 public endTime;
    uint64 participantsLength;
    uint limitedTicket;

    mapping(uint64 => Participant) randomUsers;

    event TicketPurchased(address indexed participant);
    event WinnerPicked(uint);

    struct LastError {
        euint8 error;
        uint timestamp;
    }

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
        winner = TFHE.asEaddress(address(0));
        participantsLength = 0;
        endTime = 0;
    }

    function start(uint256 _ticketPrice, uint256 _duration, uint256 _limitedTicked) private {
        ticketPrice = _ticketPrice;
        endTime = block.timestamp + _duration;
        limitedTicket = _limitedTicked;
    }

    function setLastError(euint8 error, address addr) private {
        _lastErrors[addr] = LastError(error, block.timestamp);
        emit ErrorChanged(addr);
    }

    function buyTicket(einput _eUser, einput _eAmount, bytes calldata inputProof) external {
        require(endTime > 0, "the tombola is not starting ");
        require(block.timestamp < endTime, "Tombola has ended");
        /*if (limitedTicket > 0 ) {
            require()
        }*/

        euint64 eAmount = TFHE.asEuint64(_eAmount, inputProof);
        TFHE.allow(eAmount, address(this));

        eaddress eUser = TFHE.asEaddress(_eUser, inputProof);
        TFHE.allow(eUser, address(this));

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

    function pickWinner() external {
        require(block.timestamp >= endTime, "Tombola is still ongoing");
        require(participantsLength > 0, "No participants");
        //require(token.balanceOf(address(this)) > 0, "no token on smart contract");
        setLastError(TFHE.select(TFHE.gt(token.balanceOf(address(this)), ZERO), NO_ERROR, ERROR), msg.sender);

        euint64 randomNumber = getRandom();
        euint64 minDifference = TFHE.sub(randomNumber, randomNumber);

        TFHE.allowTransient(minDifference, address(this));

        for (uint32 i = 0; i < participantsLength; i++) {
            euint64 eRandomNumberUser = randomUsers[i].eRandomUsers;
            eaddress eAddressUser = randomUsers[i].eAddress;

            euint64 difference = TFHE.sub(eRandomNumberUser, randomNumber);
            ebool isSmaller = TFHE.lt(difference, minDifference);

            minDifference = TFHE.select(isSmaller, difference, minDifference);
            winner = TFHE.select(isSmaller, eAddressUser, winner);
        }

        TFHE.allow(winner, address(this));

        emit WinnerPicked(block.timestamp);
    }
}
