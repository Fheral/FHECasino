// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "fhevm/lib/TFHE.sol";

interface ITicket {
    struct Participant {
        eaddress eAddress;
        euint64 eNumberRandom;
    }

    struct Taxes {
        euint64 eTaxFactory;
        euint64 eTaxCreatorTicket;
        euint64 eAmountFeesFactory;
        euint64 eAmountCreatorTicket;
    }

    struct Owners {
        address creatorTicket;
        address factoryAddr;
    }

    function eNumberWin() external view returns (euint64);
    function numberWinDecrypt() external view returns (uint64);
    function ticketPrice() external view returns (uint256);
    function endTime() external view returns (uint256);
    function participantsLength() external view returns (uint64);
    function isFinish() external view returns (bool);
    function limitedTicket() external view returns (uint);
    function eAmountWinner() external view returns (euint64);
    function owners() external view returns (Owners memory);
    function eTaxes() external view returns (Taxes memory);

    function getRandom() external returns (euint64);
    function getBalanceContract() external view returns (euint64);

    function buyTicket(einput _eUser, einput _eAmount, bytes calldata inputProof) external;
    function claimTokensWinner() external;
    function claimTokensCreator() external;
    function claimTokensFactory() external;
    function distributeProfits() external;
    function pickWinner() external;
}
