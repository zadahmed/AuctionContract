// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Auction Contract
 * @dev Implements an upgradeable auction system for ERC20 tokens.
 */
contract Auction is Initializable, OwnableUpgradeable {
    // Represents a bid with the bidder's details, bid amount, and price per token.
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 price;
    }

    // Represents an auction with token details, end time, total amount, and bids.
    struct AuctionDetail {
        IERC20Upgradeable token;
        uint256 endTime;
        uint256 amount;
        Bid[] bids;
    }

    // Mapping of auctionId to its details.
    mapping(uint256 => AuctionDetail) public auctions;

    // Count of auctions initialized.
    uint256 public auctionCount;

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
        require(IERC20Upgradeable(tokenAddress).balanceOf(address(this)) >= amount, "Not enough tokens in contract");
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
        require(msg.sender != owner(), "Only non-owners can participate");
        require(auctionId < auctionCount, "Invalid auctionId");
        require(block.timestamp < auctions[auctionId].endTime, "Auction ended");
        // Logic to insert bids in descending order of price.
        uint256 index = auctions[auctionId].bids.length; // default to end
        for (uint256 i = 0; i < auctions[auctionId].bids.length;) {
            if (price >= auctions[auctionId].bids[i].price) {
                index = i;
                break;
            }
            unchecked {
                i++;
            }
        }
        auctions[auctionId].bids.push(Bid({bidder: address(0), amount: 0, price: 0}));
        for (uint256 j = auctions[auctionId].bids.length - 1; j > index;) {
            auctions[auctionId].bids[j] = auctions[auctionId].bids[j - 1];
            unchecked {
                j--;
            }
        }
        auctions[auctionId].bids[index] = Bid({bidder: msg.sender, amount: amount, price: price});
    }

    /**
     * @dev Ends an auction and transfers tokens to the highest bidder.
     * @param auctionId ID of the auction to be ended.
     */
    function endAuction(uint256 auctionId) external onlyOwner {
        require(auctionId < auctionCount, "Invalid auctionId");
        require(block.timestamp >= auctions[auctionId].endTime, "Auction not yet ended");

        if (auctions[auctionId].bids.length > 0) {
            Bid memory highestBid = auctions[auctionId].bids[0];
            require(highestBid.amount <= auctions[auctionId].amount, "Bid amount exceeds auction amount");

            auctions[auctionId].token.transfer(highestBid.bidder, highestBid.amount);
            auctions[auctionId].amount -= highestBid.amount;
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
        require(bidIndex < auctions[auctionId].bids.length, "Bid index out of bounds");
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
