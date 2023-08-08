import { ethers } from "hardhat";
import { expect } from "chai";
import { BigNumber } from "ethers";

import { increaseTime } from "./utils/time";


describe("Auction", function () {
  let auction: any;
  let token: any;
  let owner: any;
  let addr1: any;
  let addr2: any;
  let addr3: any;

  beforeEach(async function () {
    // Deploying the mock token and the auction contracts
    const Token = await ethers.getContractFactory("MockERC20");
    token = await Token.deploy("Mock Token", "MTK");

    const Auction = await ethers.getContractFactory("Auction");
    auction = await Auction.deploy();
    auction.initialize();

    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    await token.mint(owner.address, ethers.utils.parseEther("1000"));
    await token.transfer(auction.address, ethers.utils.parseEther("1000"));

  });

  it("Should start an auction correctly", async function () {
    await auction.connect(owner).startAuction(
      token.address,
      ethers.utils.parseEther("100"),
      3600
    );
    expect((await auction.auctionCount()).eq(BigNumber.from(1))).to.be.true;
  });

  it("Should allow users to place bids", async function () {
    await auction.connect(owner).startAuction(
      token.address,
      ethers.utils.parseEther("100"),
      3600
    );

    await auction
      .connect(addr1)
      .placeBid(0, ethers.utils.parseEther("10"), ethers.utils.parseEther("1"));
    await auction
      .connect(addr2)
      .placeBid(0, ethers.utils.parseEther("20"), ethers.utils.parseEther("2"));
    await auction
      .connect(addr3)
      .placeBid(
        0,
        ethers.utils.parseEther("30"),
        ethers.utils.parseEther("0.5")
      );

    const bidCount = await auction.getBidCount(0);
    expect(bidCount.eq(BigNumber.from(3))).to.be.true;

    const highestBid = await auction.getBid(0, 0);
    expect(highestBid.bidder).to.equal(addr2.address);
    expect(highestBid.amount.eq(ethers.utils.parseEther("20"))).to.be.true;
    expect(highestBid.price.eq(ethers.utils.parseEther("2"))).to.be.true;
  });


  it("Non-owner should not be able to start an auction", async function () {
    await expect(
      auction.connect(addr1).startAuction(
        token.address,
        ethers.utils.parseEther("100"),
        3600
      )
    ).to.be.revertedWith("Ownable: caller is not the owner");    
  });

  it("Only owner can end an auction immediately after its time", async function () {
    await auction.connect(owner).startAuction(
      token.address,
      ethers.utils.parseEther("100"),
      10 // set a short duration for test
    );
    await increaseTime(10); // move 10 seconds into the future

    await expect(
      auction.connect(addr1).endAuction(0)
    ).to.be.revertedWith(
      'Ownable: caller is not the owner'
    );

    await auction.connect(owner).endAuction(0); // This should not revert
  });


  it("Ending an auction should transfer tokens to the highest bidder", async function () {
    await auction.connect(owner).startAuction(
      token.address,
      ethers.utils.parseEther("100"),
      10 // set a short duration for test
    );

    await auction
      .connect(addr1)
      .placeBid(0, ethers.utils.parseEther("10"), ethers.utils.parseEther("1"));
    await auction
      .connect(addr2)
      .placeBid(0, ethers.utils.parseEther("20"), ethers.utils.parseEther("2"));

    await increaseTime(10); // move 10 seconds into the future
    await auction.connect(owner).endAuction(0);

    expect(
      await token.balanceOf(addr2.address)
    ).to.equal(ethers.utils.parseEther("20"));
  });

});
