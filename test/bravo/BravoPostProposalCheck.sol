pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import {GovernorBravoDelegator} from "@comp-governance/GovernorBravoDelegator.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {MockERC20Votes} from "@forge-proposal-simulator/mocks/MockERC20Votes.sol";
import {Timelock} from "@forge-proposal-simulator/mocks/bravo/Timelock.sol";
import {GovernorBravoDelegate} from "@forge-proposal-simulator/mocks/bravo/GovernorBravoDelegate.sol";

import {MockBravoProposal} from "proposals/MockBravoProposal.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract BravoPostProposalCheck is Test {
    Addresses public addresses;

    function setUp() public {
        addresses = new Addresses("./addresses/Addresses.json");
        vm.makePersistent(address(addresses));

        MockBravoProposal bravoProposal = new MockBravoProposal();

        // Set the addresses contract
        bravoProposal.setAddresses(addresses);

        // Verify if the governor address is a contract; if is not (e.g. running on a empty blockchain node), deploy a new governor and update the address.
        address governor = addresses.getAddress("PROTOCOL_GOVERNOR");
        uint256 governorSize;
        assembly {
            // retrieve the size of the code, this needs assembly
            governorSize := extcodesize(governor)
        }
        if (governorSize == 0) {
            // Deploy and configure the timelock
            Timelock timelock = new Timelock(address(this), 1);

            // Deploy the governance token
            MockERC20Votes govToken = new MockERC20Votes("Governance Token", "GOV");

            govToken.mint(address(this), 1e21);

            // Deploy the GovernorBravoDelegate implementation
            GovernorBravoDelegate implementation = new GovernorBravoDelegate();

            // Deploy and configure the GovernorBravoDelegator
            GovernorBravoDelegator governor = new GovernorBravoDelegator(
                address(timelock), // timelock
                address(govToken), // governance token
                address(this), // admin
                address(implementation), // implementation
                10_000, // voting period
                10_000, // voting delay
                1e21 // proposal threshold
            );

            timelock.queueTransaction(
                address(timelock),
                0,
                "",
                abi.encodeWithSignature(
                    "setPendingAdmin(address)",
                    address(governor)
                ),
                block.timestamp + 180
            );

            // Update PROTOCOL_GOVERNOR address
            addresses.changeAddress(
                "PROTOCOL_GOVERNOR",
                address(governor),
                true
            );

            // Execute proposals
            bravoProposal.run();
        }
    }
}
