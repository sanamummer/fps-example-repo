pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import {MockTimelockProposal} from "proposals/MockTimelockProposal.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import { TimelockController } from "@openzeppelin/governance/TimelockController.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract TimelockPostProposalCheck is Test {
    Addresses public addresses;

    function setUp() public {
        addresses = new Addresses("./addresses/Addresses.json");
        vm.makePersistent(address(addresses));

        MockTimelockProposal timelockProposal = new MockTimelockProposal();

        // Set the addresses contract
        timelockProposal.setAddresses(addresses);

        // Verify if the timelock address is a contract; if is not (e.g. running on a empty blockchain node), deploy a new TimelockController and update the address.
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK");
        uint256 timelockSize;
        assembly {
            // retrieve the size of the code, this needs assembly
            timelockSize := extcodesize(timelock)
        }
        if (timelockSize == 0) {
            // Get proposer and executor addresses
            address proposer = addresses.getAddress("TIMELOCK_PROPOSER");
            address executor = addresses.getAddress("TIMELOCK_PROPOSER");

            // Create arrays of addresses to pass to the TimelockController constructor
            address[] memory proposers = new address[](1);
            proposers[0] = proposer;
            address[] memory executors = new address[](1);
            executors[0] = executor;

            // Deploy a new TimelockController
            TimelockController timelockController = new TimelockController(
                10_000,
                proposers,
                executors,
                address(0)
            );

            // Update PROTOCOL_TIMELOCK address
            addresses.changeAddress(
                "PROTOCOL_TIMELOCK",
                address(timelockController),
                true
            );

            // Execute proposals
            timelockProposal.run();
        }
    }
}
