// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import { MVRGDA } from "./MVRGDA.sol";
import { unsafeWadDiv } from "solmate/utils/SignedWadMath.sol";

/// @title Linear Variable Rate Gradual Dutch Auction with Martingale Price Correction
/// @author asnared <https://github.com/abigger87>
/// @notice Adapted from transmissions11 <t11s@paradigm.xyz>
/// @notice Adapted from FrankieIsLost <frankie@paradigm.xyz>
/// @notice MVRGDA with a linear issuance curve.
abstract contract LinearMVRGDA is MVRGDA {

    /// [[[[[[[[[[[[[[[[[[[[[[[[[  PRICE PARAMS  ]]]]]]]]]]]]]]]]]]]]]]]]]

    /// @dev The total number of tokens to target selling every full unit of time.
    /// @dev Represented as an 18 decimal fixed point number.
    int256 internal immutable perTimeUnit;

    /// @notice Sets pricing parameters for the VRGDA.
    /// @param _targetPrice The target price for a token if sold on pace, scaled by 1e18.
    /// @param _priceDecayPercent The percent price decays per unit of time with no sales, scaled by 1e18.
    /// @param _perTimeUnit The number of tokens to target selling in 1 full unit of time, scaled by 1e18.
    constructor(
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _perTimeUnit
    ) MVRGDA(_targetPrice, _priceDecayPercent) {
        perTimeUnit = _perTimeUnit;
    }

    /// [[[[[[[[[[[[[[[[[[[[[[[[[  PRICE LOGIC  ]]]]]]]]]]]]]]]]]]]]]]]]]

    /// @dev Given a number of tokens sold, return the target time that number of tokens should be sold by.
    /// @param sold A number of tokens sold, scaled by 1e18, to get the corresponding target sale time for.
    /// @return The target time the tokens should be sold by, scaled by 1e18, where the time is
    /// relative, such that 0 means the tokens should be sold immediately when the VRGDA begins.
    function getTargetSaleTime(int256 sold) public view virtual override returns (int256) {
        return unsafeWadDiv(sold, perTimeUnit);
    }

    /// @notice Get the current amount of reserves.
    /// @return The current reserves, scaled by 1e18.
    function getCurrentReserves() public view override returns (uint256) {
        return address(this).balance;
    }
}
