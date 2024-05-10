pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import { MockMultisigProposal_01 } from "proposals/MockMultisigProposal_01.sol";

import { Addresses } from "@forge-proposal-simulator/addresses/Addresses.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract MultisigPostProposalCheck is Test {
    Addresses public addresses;
    
    function setUp() public virtual {

        MockMultisigProposal_01 multisigProposal = new MockMultisigProposal_01();

        // Execute proposals
        multisigProposal.run();

        addresses = multisigProposal.addresses();
    }
}
