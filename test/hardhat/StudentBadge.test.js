const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("StudentBadge Hardhat Tests", function () {
  let studentBadge, owner, addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();
    
    const StudentBadgeFactory = await ethers.getContractFactory("StudentBadge");
    studentBadge = await StudentBadgeFactory.deploy();
    await studentBadge.waitForDeployment();
  });

  describe("Deployment (Deploy)", function () {
    it("Should deploy successfully with correct standard configurations", async function () {
      expect(await studentBadge.getAddress()).to.be.properAddress;
    });
  });

  describe("Minting (Emissao do Cracha)", function () {
    it("Should allow a user to mint their first StudentBadge", async function () {
      await expect(studentBadge.connect(addr1).mint())
        .to.emit(studentBadge, "Transfer");
      
      expect(await studentBadge.balanceOf(addr1.address)).to.equal(1);
    });

    it("Should revert if a user tries to mint more than one badge", async function () {
      await studentBadge.connect(addr1).mint();
      
      await expect(studentBadge.connect(addr1).mint()).to.be.reverted;
    });
  });
});