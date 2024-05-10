pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import { Addresses } from "@forge-proposal-simulator/addresses/Addresses.sol";

import { MockBravoProposal_01 } from "proposals/MockBravoProposal_01.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract BravoPostProposalCheck is Test {
    Addresses public addresses;

    function setUp() public {
        MockBravoProposal_01 bravoProposal = new MockBravoProposal_01();

        // Execute proposals
        bravoProposal.run();

        // Get the addresses contract
        addresses = bravoProposal.addresses();
    }
}
