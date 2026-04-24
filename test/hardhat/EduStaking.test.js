const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("EduStaking Hardhat Tests", function () {
  let studentBadge, eduStaking, owner, addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    const BadgeFactory = await ethers.getContractFactory("StudentBadge");
    studentBadge = await BadgeFactory.deploy();
    await studentBadge.waitForDeployment();
    const badgeAddress = await studentBadge.getAddress();

    const TokenFactory = await ethers.getContractFactory("EduToken");
    const eduToken = await TokenFactory.deploy(owner.address);
    await eduToken.waitForDeployment();
    const tokenAddress = await eduToken.getAddress();

    const mockOracleAddress = owner.address;
    const StakingFactory = await ethers.getContractFactory("EduStaking");
    eduStaking = await StakingFactory.deploy(badgeAddress, tokenAddress, mockOracleAddress); 
    await eduStaking.waitForDeployment();
  });

  describe("Staking Mechanics (Mecanica de Stake/Unstake)", function () {
    let tokenId = 0;

    beforeEach(async function () {
      await studentBadge.connect(addr1).mint();
    });

    it("Should revert if user tries to stake an NFT they do not own", async function () {
      await expect(eduStaking.connect(owner).stake(tokenId))
        .to.be.revertedWithCustomError(eduStaking, "EduStaking__NotOwnerOfNFT");
    });

    it("Should allow the owner to stake their NFT after approving", async function () {
      const stakingAddress = await eduStaking.getAddress();
      
      await studentBadge.connect(addr1).approve(stakingAddress, tokenId);
      
      await expect(eduStaking.connect(addr1).stake(tokenId)).to.not.be.reverted;
      expect(await studentBadge.ownerOf(tokenId)).to.equal(stakingAddress);
    });

    it("Should revert if user tries to unstake before the 30 seconds TimeLock", async function () {
      const stakingAddress = await eduStaking.getAddress();
      await studentBadge.connect(addr1).approve(stakingAddress, tokenId);
      await eduStaking.connect(addr1).stake(tokenId);

      await expect(eduStaking.connect(addr1).unstake(tokenId))
        .to.be.revertedWithCustomError(eduStaking, "EduStaking__StakingTimeNotMet");
    });
  });
});