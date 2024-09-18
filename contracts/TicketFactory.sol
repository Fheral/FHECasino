// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Ticket.sol";

contract TicketFactory {
    // Stocker les adresses des contrats Ticket déployés
    address[] public deployedTickets;
    mapping(address => address) ownerOfTicket;

    event TicketCreated(address ticketAddress, address owner);

    // Fonction pour créer un nouveau contrat Ticket
    function createTicket(uint64 amount, address _token, string memory _name, string memory _symbol) external {
        // Déployer un nouveau contrat Ticket
        Ticket newTicket = new Ticket(msg.sender, amount, _name, _symbol, _token);

        // Ajouter l'adresse du contrat déployé à la liste
        deployedTickets.push(address(newTicket));

        ownerOfTicket[msg.sender] = address(newTicket);

        // Émettre un événement pour indiquer qu'un nouveau Ticket a été créé
        emit TicketCreated(address(newTicket), msg.sender);
    }

    // Obtenir le nombre de tickets déployés
    function getDeployedTickets() external view returns (address[] memory) {
        return deployedTickets;
    }
}
