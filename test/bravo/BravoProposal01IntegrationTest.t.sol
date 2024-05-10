pragma solidity ^0.8.0;

import {Vault} from "proposals/utils/Vault.sol";
import {Token} from "proposals/utils/Token.sol";
import {BravoPostProposalCheck} from "./BravoPostProposalCheck.sol";

// @dev This test contract extends BravoPostProposalCheck, granting it
// the ability to interact with state modifications effected by proposals
// and to work with newly deployed contracts, if applicable.
contract BravoProposal01IntegrationTest is BravoPostProposalCheck {
    function test_addTokenToWhitelist() public {
        Vault governorVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO");
        Token token = new Token();

        vm.prank(timelock);

        governorVault.whitelistToken(address(token), true);

        assertTrue(governorVault.tokenWhitelist(address(token)), "Token should be whitelisted");
    }

    function test_depositToVault() public {
        Vault governorVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO");
        address token = addresses.getAddress("BRAVO_VAULT_TOKEN");

        vm.startPrank(timelock);
        Token(token).mint(timelock, 100);
        Token(token).approve(address(governorVault), 100);
        governorVault.deposit(address(token), 100);

        (uint256 amount,) = governorVault.deposits(token, timelock);
        assertTrue(amount == (1e25 + 100), "Token should be deposited");
    }
}
