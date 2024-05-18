// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    Proposal[] proposals;
    mapping (address => uint) proposalIds;
    mapping (address => Voter) voters;
    mapping (address => bool) whitelist;

    WorkflowStatus public currentWorkflowStatus = WorkflowStatus.RegisteringVoters;

    constructor(address initialOwner) Ownable(initialOwner) {
        whitelist[initialOwner] = true;
    }

    modifier isInWhiteList {
      require(whitelist[msg.sender] == true, "non autorise");
      _;
   }

    //L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum.
    function setWhiteList(address _address) public onlyOwner {
        whitelist[_address] = true;
    }
    
    //L'administrateur du vote commence la session d'enregistrement de la proposition.
    function openProposalSession() public onlyOwner {
        emit WorkflowStatusChange(currentWorkflowStatus, WorkflowStatus.ProposalsRegistrationStarted);
        currentWorkflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
    }

    //Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active. 
    function storeVotersProposal(string memory _description) public isInWhiteList {
        require(currentWorkflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "session non ouverte");   
        proposals.push(Proposal(_description, 0));
        proposalIds[msg.sender] = proposals.length;
        emit ProposalRegistered(proposalIds[msg.sender]);
    }

    //L'administrateur de vote met fin à la session d'enregistrement des propositions.
    function closeProposalSession() public onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "session non ouverte");
        emit WorkflowStatusChange(currentWorkflowStatus, WorkflowStatus.ProposalsRegistrationEnded);
        currentWorkflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
    }

    //L'administrateur du vote commence la session de vote.
    function openVotingSession() public onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "session non fermee");
        require(proposals.length > 0, "aucune proposition");
        emit WorkflowStatusChange(currentWorkflowStatus, WorkflowStatus.VotingSessionStarted);
        currentWorkflowStatus = WorkflowStatus.VotingSessionStarted;
    }

    //Les électeurs inscrits votent pour leur proposition préférée.
    function vote(uint _indexProposalId) public isInWhiteList {
        require(currentWorkflowStatus == WorkflowStatus.VotingSessionStarted, "session non ouverte");
        require(!voters[msg.sender].hasVoted, "A deja vote");

        for(uint i = 0; i < proposals.length; i++) {
            if (_indexProposalId == i) {
                voters[msg.sender].isRegistered = true;
                voters[msg.sender].hasVoted = true;
                voters[msg.sender].votedProposalId = _indexProposalId;
                proposals[i].voteCount++;
                emit Voted (msg.sender, _indexProposalId);
            }
        }
    }

    //L'administrateur du vote met fin à la session de vote.
    function closeVotingSession() public onlyOwner {
        emit WorkflowStatusChange(currentWorkflowStatus, WorkflowStatus.VotingSessionEnded);
        currentWorkflowStatus = WorkflowStatus.VotingSessionEnded;
    }

    //L'administrateur du vote comptabilise les votes.
    function countVotes() public onlyOwner returns(Proposal[] memory) {
        require(currentWorkflowStatus == WorkflowStatus.VotingSessionEnded, "session non fermee");
        emit WorkflowStatusChange(currentWorkflowStatus, WorkflowStatus.VotesTallied);
        currentWorkflowStatus = WorkflowStatus.VotesTallied;
        return proposals;
    }

    //retourne la proposition gagnante    
    function getWinner() public onlyOwner view returns(uint) {
        require(currentWorkflowStatus == WorkflowStatus.VotesTallied, "Vote non comptabilises");
        uint winningProposalId = 0;
        uint maxVotes = 0;
        for(uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > maxVotes) {
                winningProposalId = i;
                maxVotes = proposals[i].voteCount;
            } 
        }

        return winningProposalId;
    }

    //Tout le monde peut vérifier les derniers détails de la proposition gagnante.
    function getVotesDetails(uint _proposalId) public view returns(uint) {
        for(uint i = 0; i < proposals.length; i++) {
            if (_proposalId == i) {
                return proposals[i].voteCount;
            }
        }

        return 0;
    }
}