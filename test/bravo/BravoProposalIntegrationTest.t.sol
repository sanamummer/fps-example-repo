pragma solidity ^0.8.0;

import {Vault} from "@forge-proposal-simulator/mocks/Vault.sol";
import {Token} from "@forge-proposal-simulator/mocks/Token.sol";
import {BravoPostProposalCheck} from "./BravoPostProposalCheck.sol";

// @dev This test contract extends BravoPostProposalCheck, granting it
// the ability to interact with state modifications effected by proposals
// and to work with newly deployed contracts, if applicable.
contract BravoProposalIntegrationTest is BravoPostProposalCheck {
    function test_vaultIsPausable() public {
        Vault governorVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        address governor = addresses.getAddress("PROTOCOL_GOVERNOR");

        vm.prank(governor);

        governorVault.pause();

        assertTrue(governorVault.paused(), "Vault should be paused");
    }

    function test_addTokenToWhitelist() public {
        Vault governorVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        address governor = addresses.getAddress("PROTOCOL_GOVERNOR");
        Token token = new Token();

        vm.prank(governor);

        governorVault.whitelistToken(address(token), true);

        assertTrue(
            governorVault.tokenWhitelist(address(token)),
            "Token should be whitelisted"
        );
    }

    function test_depositToVault() public {
        Vault governorVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        address governor = addresses.getAddress("PROTOCOL_GOVERNOR");
        address token = addresses.getAddress("BRAVO_VAULT_TOKEN");

        vm.startPrank(governor);
        Token(token).mint(governor, 100);
        Token(token).approve(address(governorVault), 100);
        governorVault.deposit(address(token), 100);

        (uint256 amount, ) = governorVault.deposits(address(token), governor);
        assertTrue(amount == 100, "Token should be deposited");
    }
}
