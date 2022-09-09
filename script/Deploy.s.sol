// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import { Script } from 'forge-std/Script.sol';

import { MVRGDA } from "src/MVRGDA.sol";

/// @notice A very simple deployment script
contract Deploy is Script {
  /// @notice The main script entrypoint
  /// @return mvrgda The deployed contract
  function run() external returns (MVRGDA mvrgda) {
    vm.startBroadcast();
    mvrgda = new MVRGDA();
    vm.stopBroadcast();
  }
}