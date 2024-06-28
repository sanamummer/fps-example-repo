pragma solidity ^0.8.0;

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";
import {OZGovernorPostProposalCheck} from "./OZGovernorPostProposalCheck.sol";

// @dev This test contract extends OZGovernorPostProposalCheck, granting it
// the ability to interact with state modifications effected by proposals
// and to work with newly deployed contracts, if applicable.
contract OZGovernorVaultIntegrationTestSepolia is OZGovernorPostProposalCheck {
    function test_addTokenToWhitelist() public {
        Vault OZGovernorVault = Vault(addresses.getAddress("OZ_GOVERNOR_VAULT"));
        address OZGovernorTimelock = addresses.getAddress("OZ_GOVERNOR_TIMELOCK");
        Token token = new Token();

        vm.prank(OZGovernorTimelock);

        OZGovernorVault.whitelistToken(address(token), true);

        assertTrue(
            OZGovernorVault.tokenWhitelist(address(token)),
            "Token should be whitelisted"
        );
    }

    function test_depositToVault() public {
        Vault OZGovernorVault = Vault(addresses.getAddress("OZ_GOVERNOR_VAULT"));
        address OZGovernorTimelock = addresses.getAddress("OZ_GOVERNOR_TIMELOCK");
        address governanceToken = addresses.getAddress("OZ_GOVERNOR_VAULT_TOKEN");
        (uint256 prevDeposit, ) = OZGovernorVault.deposits(governanceToken, OZGovernorTimelock);
        uint256 depositAmount = 100;

        vm.startPrank(OZGovernorTimelock);
        Token(governanceToken).mint(OZGovernorTimelock, depositAmount);
        Token(governanceToken).approve(address(OZGovernorVault), depositAmount);
        OZGovernorVault.deposit(address(governanceToken), depositAmount);

        (uint256 amount, ) = OZGovernorVault.deposits(governanceToken, OZGovernorTimelock);
        assertTrue(
            amount == (prevDeposit + depositAmount),
            "Token should be deposited"
        );
    }
}
