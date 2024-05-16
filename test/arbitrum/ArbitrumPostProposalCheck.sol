pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {ArbitrumProposal} from "src/proposals/ArbitrumProposal.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract ArbitrumPostProposalCheck is Test {
    Addresses internal addresses;

    function setUp() public {}
    function test_setUp() public {
        string[] memory inputs = new string[](2);
        inputs[0] = "./get-latest-proposal.sh";
        inputs[1] = "ArbitrumProposal";

        string memory output = string(vm.ffi(inputs));

        ArbitrumProposal proposal = ArbitrumProposal(deployCode(output));
        vm.makePersistent(address(proposal));

        // Execute proposal
        proposal.run();

        // Get the addresses contract
        addresses = proposal.addresses();
    }
}
