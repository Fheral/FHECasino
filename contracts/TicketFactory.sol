// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Ticket.sol";
import "./interfaces/ITicket.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

contract TicketFactory is Ownable2Step {
    address[] public deployedTickets;
    mapping(address => address) ownerOfTicket;

    event TicketCreated(address ticketAddress, address owner);

    constructor() Ownable(msg.sender) {}

    function createTickets(uint amount, address _token, string memory _name, string memory _symbol) external {
        Ticket newTicket = new Ticket(msg.sender, amount, _name, _symbol, _token);

        deployedTickets.push(address(newTicket));

        ownerOfTicket[msg.sender] = address(newTicket);

        emit TicketCreated(address(newTicket), msg.sender);
    }

    function getDeployedTickets() external view returns (address[] memory) {
        return deployedTickets;
    }

    function claimTokensFactory() external onlyOwner {
        for (uint256 i = 0; i < deployedTickets.length; i++) {
            ITicket(deployedTickets[i]).claimTokensFactory();
        }
    }
}
