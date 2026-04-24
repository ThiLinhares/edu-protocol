const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("EduToken Hardhat Tests", function () {
  let eduToken, owner, mockStakingContract, addr1;

  beforeEach(async function () {
    [owner, mockStakingContract, addr1] = await ethers.getSigners();
    
    const EduTokenFactory = await ethers.getContractFactory("EduToken");
    eduToken = await EduTokenFactory.deploy(owner.address);
    await eduToken.waitForDeployment();

    await eduToken.setStakingContract(mockStakingContract.address);
  });

  describe("Access Control & Minting (Controle de Emissao)", function () {
    it("Should allow the authorized Staking contract to mint tokens", async function () {
      const mintAmount = ethers.parseEther("50");
      
      await expect(eduToken.connect(mockStakingContract).mint(addr1.address, mintAmount))
        .to.emit(eduToken, "Transfer")
        .withArgs(ethers.ZeroAddress, addr1.address, mintAmount);

      expect(await eduToken.balanceOf(addr1.address)).to.equal(mintAmount);
    });

    it("Should revert with custom error if an unauthorized account tries to mint", async function () {
      const mintAmount = ethers.parseEther("50");
      
      await expect(eduToken.connect(addr1).mint(addr1.address, mintAmount))
        .to.be.revertedWithCustomError(eduToken, "EduToken__OnlyStakingContract");
    });
  });
});