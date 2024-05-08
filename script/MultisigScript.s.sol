pragma solidity ^0.8.0;

import "forge-std/Script.sol";

import {MockMultisigProposal} from "proposals/MockMultisigProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

// @notice MultisigScript is a script that run MockMultisigProposal proposal
// MockMultisigProposal proposal deploys a Vault contract and an ERC20 token contract
// Then the proposal transfers ownership of both Vault and ERC20 to the multisig address
// Finally the proposal whitelist the ERC20 token in the Vault contract
// @dev Use this script to simulates or run a single proposal
// Use this as a template to create your own script
// `forge script script/Multisig.s.sol:MultisigScript -vvvv --rpc-url {rpc} --broadcast --verify --etherscan-api-key {key}`
contract MultisigScript is Script {

    bytes public constant SAFE_BYTECODE =
        hex"608060405273ffffffffffffffffffffffffffffffffffffffff600054167fa619486e0000000000000000000000000000000000000000000000000000000060003514156050578060005260206000f35b3660008037600080366000845af43d6000803e60008114156070573d6000fd5b3d6000f3fea2646970667358221220d1429297349653a4918076d650332de1a1068c5f3e07c5c82360c277770b955264736f6c63430007060033";

    function run() public {
        MockMultisigProposal multisigProposal = new MockMultisigProposal();
        Addresses addresses = multisigProposal.addresses();

        /// only set the safe bytecode if testing locally
        if (block.chainid == 31337) {
            // Set Gnosis Safe bytecode
            vm.etch(addresses.getAddress("DEV_MULTISIG"), SAFE_BYTECODE);
        }

        // Execute proposal
        multisigProposal.run();
    }
}
