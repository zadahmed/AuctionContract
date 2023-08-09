// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

abstract contract AuctionStorage {
    // Represents a bid with the bidder's details, bid amount, and price per token.
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 price;
        uint256 lockedAmount; 
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

    // Custom errors
    error InsufficientTokensInContract();
    error InsufficientFunds();
    error InvalidAuctionId();
    error AuctionEnded();
    error OwnerCannotParticipate();
    error BidAmountExceedsAuctionAmount();
    error AuctionNotYetEnded();
    error BidIndexOutOfBounds();
    error BidNotFound();
}
