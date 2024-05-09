pragma solidity ^0.8.0;

import {Vault} from "@forge-proposal-simulator/mocks/Vault.sol";
import {Token} from "@forge-proposal-simulator/mocks/Token.sol";
import {MultisigPostProposalCheck} from "./MultisigPostProposalCheck.sol";

// @dev This test contract inherits MultisigPostProposalCheck, granting it
// the ability to interact with state modifications effected by proposals
// and to work with newly deployed contracts, if applicable.
contract MultisigProposalIntegrationTest is MultisigPostProposalCheck {
    // Tests if the Vault contract can be paused
    // function test_vaultIsPausable() public {
    //     // Retrieves the Vault instance using its address from the Addresses contract
    //     Vault multisigVault = Vault(addresses.getAddress("MULTISIG_VAULT"));
    //     // Retrieves the address of the multisig wallet
    //     address multisig = addresses.getAddress("DEV_MULTISIG");

    //     // Sets the next caller of the function to be the multisig address
    //     vm.prank(multisig);

    //     // Executes pause function on the Vault
    //     multisigVault.pause();

    //     // Asserts that the Vault is successfully paused
    //     assertTrue(multisigVault.paused(), "Vault should be paused");
    // }

    // Tests adding a token to the whitelist in the Vault contract
    function test_addTokenToWhitelist() public {
        // Retrieves the Vault instance using its address from the Addresses contract
        Vault multisigVault = Vault(addresses.getAddress("MULTISIG_VAULT"));
        // Retrieves the address of the multisig wallet
        address multisig = addresses.getAddress("DEV_MULTISIG");
        // Creates a new instance of Token
        Token token = new Token();

        // Sets the next caller of the function to be the multisig address
        vm.prank(multisig);

        // Whitelists the newly created token in the Vault
        multisigVault.whitelistToken(address(token), true);

        // Asserts that the token is successfully whitelisted
        assertTrue(
            multisigVault.tokenWhitelist(address(token)),
            "Token should be whitelisted"
        );
    }

    // Tests deposit functionality in the Vault contract
    function test_depositToVault() public {
        // Retrieves the Vault instance using its address from the Addresses contract
        Vault multisigVault = Vault(addresses.getAddress("MULTISIG_VAULT"));
        // Retrieves the address of the multisig wallet
        address multisig = addresses.getAddress("DEV_MULTISIG");
        // Retrieves the address of the token to be deposited
        address token = addresses.getAddress("MULTISIG_TOKEN");

        // Starts a prank session with the multisig address as the caller
        vm.startPrank(multisig);
        // Mints 100 tokens to the multisig contract's address
        Token(token).mint(multisig, 100);
        // Approves the Vault to spend 100 tokens
        Token(token).approve(address(multisigVault), 100);
        // Deposits 100 tokens into the Vault
        multisigVault.deposit(address(token), 100);

        // Retrieves the deposit amount of the token in the Vault for the multisig address
        (uint256 amount, ) = multisigVault.deposits(address(token), multisig);
        // Asserts that the deposit amount is equal to 1e25 + 100
        assertTrue(amount == 1e25 + 100, "Token should be deposited");
    }
}
