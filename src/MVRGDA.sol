// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import { ERC721 } from "solmate/tokens/ERC721.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

import { toDaysWadUnsafe, toWadUnsafe } from "solmate/utils/SignedWadMath.sol";

import { LogisticVRGDA } from "../LogisticVRGDA.sol";

/// @title Martingale VRGDA ERC721 Token
/// @author asnared <https://github.com/abigger87>
/// @notice Adapted from transmissions11 <t11s@paradigm.xyz>
/// @notice Adapted from FrankieIsLost <frankie@paradigm.xyz>
/// @notice You should use in production. Not Financial Advice.
abstract contract MVRGDA is ERC721, LogisticVRGDA {
    /// @notice The maximum number of mintable tokens
    uint256 public constant MAX_MINTABLE = 100;

    /// @notice The total number of tokens sold thus far
    uint256 public totalSold;

    /// @notice The start time, immutably set to the deployment timestamp
    uint256 public immutable startTime = block.timestamp;

    constructor()
        ERC721(
            "Example Logistic NFT", // Name.
            "LOGISTIC" // Symbol.
        )
        LogisticVRGDA(
            69.42e18, // Target price.
            0.31e18, // Price decay percent.
            // Maximum # mintable/sellable.
            toWadUnsafe(MAX_MINTABLE),
            0.1e18 // Time scale.
        )
    {}

    /// @notice Mint a new token.
    function mint() external payable returns (uint256 mintedId) {
        unchecked {
            // Note: By using toDaysWadUnsafe(block.timestamp - startTime) we are establishing that 1 "unit of time" is 1 day.
            uint256 price = getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), mintedId = totalSold++);

            require(msg.value >= price, "UNDERPAID"); // Don't allow underpaying.

            _mint(msg.sender, mintedId); // Mint the NFT using mintedId.

            // Note: We do this at the end to avoid creating a reentrancy vector.
            // Refund the user any ETH they spent over the current price of the NFT.
            // Unchecked is safe here because we validate msg.value >= price above.
            SafeTransferLib.safeTransferETH(msg.sender, msg.value - price);
        }
    }

    /// @notice The Token URI for a given token id.
    /// @return uri The token uri
    function tokenURI(uint256) public pure override returns (string memory);
}