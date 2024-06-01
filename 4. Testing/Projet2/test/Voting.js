const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");   


describe("Voting Tests", () => {
  
  async function deployVoting() {

    const [owner, addr1, addr2, addr3] = await ethers.getSigners();

    const votingContract = await ethers.getContractFactory("Voting");
    const voting = await votingContract.deploy();

    return { voting , owner, addr1, addr2, addr3 };
  }

  describe.skip('Add voters', () => {
    it('should register the voter', async () => {
      const { voting, owner, addr1 } = await loadFixture(deployVoting);

      await voting.addVoter(addr1);
      const voter = await voting.connect(addr1).getVoter(addr1);
      expect(voter.isRegistered).to.be.true;
    });

    it('should return not the owner', async () => {
      const { voting, owner, addr1 } = await loadFixture(deployVoting);
      
      await expect(voting.connect(addr1).addVoter(addr1)).to.be.revertedWithCustomError(
        voting,
        "OwnableUnauthorizedAccount"
      );
    });

    it('should say voter already registered', async () => {
      const { voting, owner, addr1 } = await loadFixture(deployVoting);

      await voting.addVoter(addr1);
      await expect(voting.addVoter(addr1)).to.be.revertedWith(
        "Already registered"
      );
    });

    it('should emit a voterRegistered event', async () => {
      const { voting, owner, addr1 } = await loadFixture(deployVoting);

      expect(await voting.addVoter(addr1))
        .to.emit(voting, 'VoterRegistered')
        .withArgs(addr1);
    });
  });

  describe.skip('Add proposals', () => {
    it('should open the proposal registration', async () => {
      const { voting, owner } = await loadFixture(deployVoting);
      
      await voting.addVoter(owner);

      const workflow = await voting.startProposalsRegistering();
      expect(await voting.workflowStatus()).to.equal(1);
    });

    it('should add a proposal', async () => {
      const { voting, owner } = await loadFixture(deployVoting);
      
      await voting.addVoter(owner);
      await voting.startProposalsRegistering();

      expect(await voting.addProposal("toto"))
      .to.emit(voting, 'ProposalRegistered')
      .withArgs(1);
    });

    it('should add a proposal', async () => {
      const { voting, owner } = await loadFixture(deployVoting);
      
      await voting.addVoter(owner);

      await expect(voting.addProposal("toto")).to.be.revertedWith(
        "Proposals are not allowed yet"
      );
    });

    it('should add an empty proposal', async () => {
      const { voting, owner } = await loadFixture(deployVoting);
      
      await voting.addVoter(owner);
      await voting.startProposalsRegistering();
      await expect(voting.addProposal("")).to.be.revertedWith(
        "Vous ne pouvez pas ne rien proposer"
      );
    });
  });

  describe('test voting', () => {
    it('should say you are a voter', async () => {
      const { voting, owner, addr1 } = await loadFixture(deployVoting);
      
      await expect(voting.setVote(1)).to.be.revertedWith(
        "You are not a voter"
      );
    });

    it('should say voting session not started', async () => {
      const { voting, owner, addr1 } = await loadFixture(deployVoting);
      await voting.addVoter(owner);
      await expect(voting.setVote(1)).to.be.revertedWith(
        "Voting session havent started yet"
      );
    });

    it('should say voting session not started', async () => {
      const { voting, owner, addr1 } = await loadFixture(deployVoting);
      await voting.addVoter(owner);
      await expect(voting.setVote(1)).to.be.revertedWith(
        "Voting session havent started yet"
      );
    });

    it('should say voting session not started', async () => {
      const { voting, owner, addr1 } = await loadFixture(deployVoting);
      await voting.addVoter(owner);
      await voting.startProposalsRegistering();
      await voting.endProposalsRegistering();
      await voting.startVotingSession();
     
      await expect(voting.setVote(1)).to.be.revertedWith(
        "Proposal not found"
      );
    });

    it('should say voting session not started', async () => {
      const { voting, owner } = await loadFixture(deployVoting);
      await voting.addVoter(owner);
      await voting.startProposalsRegistering();
      await voting.addProposal("toto");
      await voting.endProposalsRegistering();
      await voting.startVotingSession();
     
      expect(await voting.setVote(1))
        .to.emit(voting, 'Voted')
        .withArgs(1);
    });
  });
});
