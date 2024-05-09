pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import {MockTimelockProposal} from "proposals/MockTimelockProposal.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract TimelockPostProposalCheck is Test {
    Addresses public addresses;

    function setUp() public {
        MockTimelockProposal timelockProposal = new MockTimelockProposal();

        // Execute proposals
        timelockProposal.run();

        // Get the addresses contract
        addresses = timelockProposal.addresses();
    }
}
