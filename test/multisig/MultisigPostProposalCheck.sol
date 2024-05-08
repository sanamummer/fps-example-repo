pragma solidity ^0.8.0;

import "@forge-std/Test.sol";

import {MockMultisigProposal} from "proposals/MockMultisigProposal.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

// @notice this is a helper contract to execute proposals before running integration tests.
// @dev should be inherited by integration test contracts.
contract MultisigPostProposalCheck is Test {
    Addresses public addresses;
    bytes public constant SAFE_BYTECODE =
        hex"608060405273ffffffffffffffffffffffffffffffffffffffff600054167fa619486e0000000000000000000000000000000000000000000000000000000060003514156050578060005260206000f35b3660008037600080366000845af43d6000803e60008114156070573d6000fd5b3d6000f3fea2646970667358221220d1429297349653a4918076d650332de1a1068c5f3e07c5c82360c277770b955264736f6c63430007060033";

    function setUp() public virtual {
        addresses = new Addresses("./addresses/Addresses.json");

        MockMultisigProposal multisigProposal = new MockMultisigProposal();

        // Set the addresses contract
        multisigProposal.setAddresses(addresses);

        // Set safe bytecode to multisig address
        vm.etch(addresses.getAddress("DEV_MULTISIG"), SAFE_BYTECODE);

        // Execute proposals
        multisigProposal.run();
    }
}
