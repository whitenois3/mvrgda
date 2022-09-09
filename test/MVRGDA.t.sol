// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import { Test } from "forge-std/Test.sol";

import {MVRGDA} from "src/MVRGDA.sol";

contract MVRGDATest is Test {
    MVRGDA token;

    function setUp() external {
        token = new MVRGDA();
    }

}
