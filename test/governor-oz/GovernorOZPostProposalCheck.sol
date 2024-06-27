pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {GovernorOZProposal} from "@forge-proposal-simulator/src/proposals/GovernorOZProposal.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract GovernorOZPostProposalCheck is Test {
    Addresses public addresses;

    function setUp() public {
        string[] memory inputs = new string[](2);
        inputs[0] = "./get-latest-proposal.sh";
        inputs[1] = "GovernorOZProposal";

        string memory output = string(vm.ffi(inputs));

        GovernorOZProposal governorOZproposal = GovernorOZProposal(
            deployCode(output)
        );
        vm.makePersistent(address(governorOZproposal));

        // Execute proposals
        governorOZproposal.run();

        // Get the addresses contract
        addresses = governorOZproposal.addresses();
    }
}