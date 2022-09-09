// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import { LinearMVRGDA } from "src/LinearMVRGDA.sol";

contract MockLinearMVRGDA is LinearMVRGDA {
    constructor(
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _perTimeUnit
    ) LinearMVRGDA(_targetPrice, _priceDecayPercent, _perTimeUnit) {}
}
