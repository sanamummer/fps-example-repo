// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @title MockArbOutbox
// @notice Mock arbitrum outbox to return L2 timelock on l2ToL1Sender call
contract MockArbOutbox {
    function l2ToL1Sender() external pure returns (address) {
        return 0x34d45e99f7D8c45ed05B5cA72D54bbD1fb3F98f0;
    }
}
