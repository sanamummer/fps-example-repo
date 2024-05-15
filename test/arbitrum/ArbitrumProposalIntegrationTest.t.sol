pragma solidity ^0.8.0;

import {ArbitrumPostProposalCheck} from "./ArbitrumPostProposalCheck.sol";

// @dev This test contract extends ArbitrumPostProposalCheck, granting it
// the ability to interact with state modifications effected by proposals
// and to work with newly deployed contracts, if applicable.
contract ArbitrumIntegrationTest is ArbitrumPostProposalCheck {
    function test_withdraw_weth() public {}
}
