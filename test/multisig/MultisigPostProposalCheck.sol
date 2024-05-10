pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import {MultisigProposal_01} from "proposals/MultisigProposal_01.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract MultisigPostProposalCheck is Test {
    Addresses public addresses;

    function setUp() public virtual {
        MultisigProposal_01 multisigProposal = new MultisigProposal_01();

        // Execute proposals
        multisigProposal.run();

        addresses = multisigProposal.addresses();
    }
}
