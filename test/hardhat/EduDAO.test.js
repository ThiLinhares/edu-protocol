const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("EduDAO Hardhat Tests", function () {
  let eduToken, eduDAO, owner, addr1, addr2;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();

    const EduTokenFactory = await ethers.getContractFactory("EduToken");
    eduToken = await EduTokenFactory.deploy(owner.address);
    await eduToken.waitForDeployment();
    const eduTokenAddress = await eduToken.getAddress();

    await eduToken.setStakingContract(owner.address);

    const EduDAOFactory = await ethers.getContractFactory("EduDAO");
    eduDAO = await EduDAOFactory.deploy(eduTokenAddress);
    await eduDAO.waitForDeployment();
  });

  describe("Deployment (Deploy)", function () {
    it("Should set the correct EDU_TOKEN address upon deployment", async function () {
      const storedTokenAddress = await eduDAO.EDU_TOKEN();
      expect(storedTokenAddress).to.equal(await eduToken.getAddress());
    });
  });

  describe("Proposals (Propostas)", function () {
    it("Should allow a user with enough tokens to create a proposal", async function () {
      const PROPOSAL_THRESHOLD = await eduDAO.PROPOSAL_THRESHOLD();
      await eduToken.connect(owner).mint(owner.address, PROPOSAL_THRESHOLD);

      const descHash = ethers.id("Test Proposal from Hardhat");
      
      await expect(eduDAO.createProposal(descHash))
        .to.emit(eduDAO, "ProposalCreated");

      const proposal = await eduDAO.proposals(0);
      expect(proposal.descriptionHash).to.equal(descHash);
    });

    it("Should revert if a user with insufficient tokens tries to create a proposal", async function () {
      const descHash = ethers.id("Failed Proposal");
      await expect(eduDAO.connect(addr1).createProposal(descHash))
        .to.be.revertedWithCustomError(eduDAO, "EduDAO__InsufficientTokensToPropose");
    });
  });

  describe("Voting (Votacao)", function () {
    let proposalId = 0;

    beforeEach(async function () {
      const PROPOSAL_THRESHOLD = await eduDAO.PROPOSAL_THRESHOLD();
      await eduToken.connect(owner).mint(owner.address, PROPOSAL_THRESHOLD);
      const descHash = ethers.id("Base Proposal");
      await eduDAO.createProposal(descHash);
    });

    it("Should allow a user with sufficient tokens to vote FOR", async function () {
      const MIN_VOTE_POWER = await eduDAO.MIN_VOTE_POWER();
      await eduToken.connect(owner).mint(addr1.address, MIN_VOTE_POWER);

      await expect(eduDAO.connect(addr1).vote(proposalId, true))
        .to.emit(eduDAO, "Voted")
        .withArgs(proposalId, addr1.address, true, MIN_VOTE_POWER);

      const proposal = await eduDAO.proposals(proposalId);
      expect(proposal.votesFor).to.equal(MIN_VOTE_POWER);
    });

    it("Should allow a user with sufficient tokens to vote AGAINST", async function () {
      const MIN_VOTE_POWER = await eduDAO.MIN_VOTE_POWER();
      await eduToken.connect(owner).mint(addr1.address, MIN_VOTE_POWER);

      await expect(eduDAO.connect(addr1).vote(proposalId, false))
        .to.emit(eduDAO, "Voted")
        .withArgs(proposalId, addr1.address, false, MIN_VOTE_POWER);

      const proposal = await eduDAO.proposals(proposalId);
      expect(proposal.votesAgainst).to.equal(MIN_VOTE_POWER);
    });

    it("Should revert if trying to vote on a non-existent proposal", async function () {
      const MIN_VOTE_POWER = await eduDAO.MIN_VOTE_POWER();
      await eduToken.connect(owner).mint(addr1.address, MIN_VOTE_POWER);

      await expect(eduDAO.connect(addr1).vote(99, true))
        .to.be.revertedWithCustomError(eduDAO, "EduDAO__ProposalDoesNotExist");
    });

    it("Should revert if user has insufficient tokens to vote", async function () {
      const MIN_VOTE_POWER = await eduDAO.MIN_VOTE_POWER();
      await eduToken.connect(owner).mint(addr1.address, MIN_VOTE_POWER - 1n);

      await expect(eduDAO.connect(addr1).vote(proposalId, true))
        .to.be.revertedWithCustomError(eduDAO, "EduDAO__InsufficientTokens");
    });

    it("Should revert if user tries to vote twice", async function () {
      const MIN_VOTE_POWER = await eduDAO.MIN_VOTE_POWER();
      await eduToken.connect(owner).mint(addr1.address, MIN_VOTE_POWER);

      await eduDAO.connect(addr1).vote(proposalId, true);

      await expect(eduDAO.connect(addr1).vote(proposalId, false))
        .to.be.revertedWithCustomError(eduDAO, "EduDAO__AlreadyVoted");
    });

    it("Should revert if voting after the deadline", async function () {
      const MIN_VOTE_POWER = await eduDAO.MIN_VOTE_POWER();
      await eduToken.connect(owner).mint(addr1.address, MIN_VOTE_POWER);

      await time.increase(3 * 24 * 60 * 60 + 1);

      await expect(eduDAO.connect(addr1).vote(proposalId, true))
        .to.be.revertedWithCustomError(eduDAO, "EduDAO__VotingClosed");
    });
  });
});
