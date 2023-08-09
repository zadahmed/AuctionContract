// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./AuctionStorage.sol";

/**
 * @title Auction Contract
 * @dev Implements an upgradeable auction system for ERC20 tokens.
 */
contract Auction is Initializable, OwnableUpgradeable, AuctionStorage {
    /**
     * @dev Initializes the auction contract and sets up owner.
     */
    function initialize() public initializer {
        __Ownable_init();
        auctionCount = 0;
    }

    /**
     * @dev Starts a new auction.
     * @param tokenAddress Address of the ERC20 token to be auctioned.
     * @param amount Total amount of tokens in the auction.
     * @param duration Duration of the auction in seconds.
     */
    function startAuction(address tokenAddress, uint256 amount, uint256 duration) external onlyOwner {
        if (IERC20Upgradeable(tokenAddress).balanceOf(address(this)) < amount) {
            revert InsufficientTokensInContract();
        }
        auctions[auctionCount].token = IERC20Upgradeable(tokenAddress);
        auctions[auctionCount].amount = amount;
        auctions[auctionCount].endTime = block.timestamp + duration;
        auctionCount++;
    }

    /**
     * @dev Allows users to place bids on an auction.
     * @param auctionId ID of the auction.
     * @param amount Amount of tokens being bid for.
     * @param price Price per token.
     */
    function placeBid(uint256 auctionId, uint256 amount, uint256 price) external {
        if (msg.sender == owner()) {
            revert OwnerCannotParticipate();
        }

        if (auctionId >= auctionCount) {
            revert InvalidAuctionId();
        }

        if (block.timestamp >= auctions[auctionId].endTime) {
            revert AuctionEnded();
        }

        auctions[auctionId].bids.push(Bid({bidder: msg.sender, amount: amount, price: price}));
    }

    /**
     * @dev Ends an auction and transfers tokens to bidders starting from the highest bid.
     * @param auctionId ID of the auction to be ended.
     */
    function endAuction(uint256 auctionId) external onlyOwner {
        if(auctionId >= auctionCount){
            revert InvalidAuctionId();
        }
        if(block.timestamp <= auctions[auctionId].endTime){
            revert AuctionNotYetEnded();
        }

        // Sort bids using insertion sort
        for (uint256 i = 1; i < auctions[auctionId].bids.length; ) {
            Bid memory key = auctions[auctionId].bids[i];
            uint256 j = i;
            while (j > 0 && auctions[auctionId].bids[j - 1].price < key.price) {
                auctions[auctionId].bids[j] = auctions[auctionId].bids[j - 1];
                j--;
            }
            auctions[auctionId].bids[j] = key;
            unchecked {
                i++;
            }
        }

        // Transfer tokens starting with the highest bid
        uint256 remainingTokens = auctions[auctionId].amount;
        for (uint256 i = 0; i < auctions[auctionId].bids.length && remainingTokens > 0; ) {
            uint256 transferAmount = (auctions[auctionId].bids[i].amount <= remainingTokens)
                ? auctions[auctionId].bids[i].amount
                : remainingTokens;
            if (transferAmount > 0) {
                auctions[auctionId].token.transfer(auctions[auctionId].bids[i].bidder, transferAmount);
                remainingTokens -= transferAmount;
            }
            unchecked {
                i++;
            }
        }

        delete auctions[auctionId].bids; // reset bids for gas refund
    }

    /**
     * @dev Fetches the details of a specific bid from an auction.
     * @param auctionId ID of the auction.
     * @param bidIndex Index of the bid in the auction's bids array.
     * @return bidder The address of the bidder.
     * @return amount The amount of the bid.
     * @return price The price per token of the bid.
     */
    function getBid(uint256 auctionId, uint256 bidIndex)
        external
        view
        returns (address bidder, uint256 amount, uint256 price)
    {
        if (bidIndex >= auctions[auctionId].bids.length) {
            revert BidIndexOutOfBounds();
        }
        Bid memory bid = auctions[auctionId].bids[bidIndex];
        return (bid.bidder, bid.amount, bid.price);
    }

    /**
     * @dev Fetches the number of bids for a specific auction.
     * @param auctionId ID of the auction.
     * @return The number of bids for the given auction.
     */
    function getBidCount(uint256 auctionId) external view returns (uint256) {
        return auctions[auctionId].bids.length;
    }
}
