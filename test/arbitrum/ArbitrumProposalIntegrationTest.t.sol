pragma solidity ^0.8.0;

import {ArbitrumPostProposalCheck} from "./ArbitrumPostProposalCheck.sol";

// @dev This test contract extends ArbitrumPostProposalCheck, granting it
// the ability to interact with state modifications effected by proposals
// and to work with newly deployed contracts, if applicable.
contract ArbitrumIntegrationTest is ArbitrumPostProposalCheck {
    /// The test is empty as the mock proposals upgrade the WETH gateway implementation to an empty contract. In a real scenario, Arbitrum would have multiple integration test contracts that would test the entire system after simulating the execution of a proposal.
    function test_finalizeInboundTransfer() public {}
}
