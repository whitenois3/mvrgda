// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import { wadExp, wadDiv, wadLn, wadMul, unsafeWadMul, toWadUnsafe } from "solmate/utils/SignedWadMath.sol";

/// @title VRGDA with Martingale Price Correction
/// @author asnared <https://github.com/abigger87>
/// @notice Adapted from transmissions11 <t11s@paradigm.xyz>
/// @notice Adapted from FrankieIsLost <frankie@paradigm.xyz>
/// @notice Something Something Recommend Using Something Financial Advice
abstract contract MVRGDA {

    /// [[[[[[[[[[[[[[[[[[[[[[  VRGDA PARAMETERS  ]]]]]]]]]]]]]]]]]]]]]]

    /// @notice Target price for a token, to be scaled according to sales pace.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 public immutable targetPrice;

    /// @dev Precomputed constant that allows us to rewrite a pow() as an exp().
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable decayConstant;

    /// @notice Sets target price and per time unit price decay for the VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    constructor(int256 _targetPrice, int256 _priceDecayPercent) {
        targetPrice = _targetPrice;

        decayConstant = wadLn(1e18 - _priceDecayPercent);

        // The decay constant must be negative for VRGDAs to work.
        require(decayConstant < 0, "NON_NEGATIVE_DECAY_CONSTANT");
    }

    /// [[[[[[[[[[[[[[[[[[[[[[[[[  PRICE LOGIC  ]]]]]]]]]]]]]]]]]]]]]]]]]

    /// @notice Calculate the price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param sold The total number of tokens that have been sold so far.
    /// @return The price of a token according to VRGDA, scaled by 1e18.
    function getVRGDAPrice(int256 timeSinceStart, uint256 sold) public view virtual returns (int256) {
        int256 rawVRGDAPrice = int256(getRawVRGDAPrice(timeSinceStart, sold));
        return rawVRGDAPrice - int256(getPushback(rawVRGDAPrice, sold));
    }

    /// @notice Calculate the raw price of a token according to the VRGDA formula.
    /// @param timeSinceStart Time passed since the VRGDA began, scaled by 1e18.
    /// @param sold The total number of tokens that have been sold so far.
    /// @return The price of a token according to VRGDA, scaled by 1e18.
    function getRawVRGDAPrice(int256 timeSinceStart, uint256 sold) public view virtual returns (uint256) {
        unchecked {
            return uint256(wadMul(targetPrice, wadExp(unsafeWadMul(decayConstant,
                // Theoretically calling toWadUnsafe with sold can silently overflow but under
                // any reasonable circumstance it will never be large enough. We use sold + 1 as
                // the VRGDA formula's n param represents the nth token and sold is the n-1th token.
                timeSinceStart - getTargetSaleTime(toWadUnsafe(sold + 1))
            ))));
        }
    }

    /// @notice Calculate the reserve pushback amount for a token sale.
    /// @param currentPrice The current VRGDA price of a token, scaled by 1e18.
    /// @param sold The total number of tokens that have been sold so far.
    /// @return The amount of reserve to pushback, scaled by 1e18.
    function getPushback(int256 currentPrice, uint256 sold) public view virtual returns (int256) {
        // constraint: pushback <= targetPrice - currentPrice
        if (currentPrice > targetPrice) {
            return 0;
        }

        /// ~~ Pushback formulae ~~
        /// uint256 delta = targetPrice - currentPrice;
        /// uint256 priceDifferential = delta / targetPrice;
        /// uint256 reflexivePriceGivenCurrentReserves = getCurrentReserves() / (sold + 1);
        /// uint256 pushback = reflexivePriceGivenCurrentReserves * priceDifferential;
        ///
        /// ~~ Inlined ~~
        /// uint256 pushback = (getCurrentReserves() * (targetPrice - currentPrice)) / (targetPrice * (sold+1))

        // Use a reflexive price calculation and scale the pushback by the current reserves
        return wadDiv(wadMul(getCurrentReserves(), targetPrice - currentPrice), wadMul(int256(sold + 1), targetPrice));
    }

    /// @notice Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold) public view virtual returns (int256);

    /// @notice Get the current amount of reserves.
    /// @return The current reserves, scaled by 1e18.
    function getCurrentReserves() public view virtual returns (int256);
}