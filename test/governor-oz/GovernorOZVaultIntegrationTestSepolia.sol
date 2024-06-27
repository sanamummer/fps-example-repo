pragma solidity ^0.8.0;

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";
import {GovernorOZPostProposalCheck} from "./GovernorOZPostProposalCheck.sol";

// @dev This test contract extends GovernorOZPostProposalCheck, granting it
// the ability to interact with state modifications effected by proposals
// and to work with newly deployed contracts, if applicable.
contract GovernorOZVaultIntegrationTestSepolia is GovernorOZPostProposalCheck {
    function test_addTokenToWhitelist() public {
        Vault governorOZVault = Vault(addresses.getAddress("GOVERNOR_OZ_VAULT"));
        address governorOZTimelock = addresses.getAddress("GOVERNOR_OZ_TIMELOCK");
        Token token = new Token();

        vm.prank(governorOZTimelock);

        governorOZVault.whitelistToken(address(token), true);

        assertTrue(
            governorOZVault.tokenWhitelist(address(token)),
            "Token should be whitelisted"
        );
    }

    function test_depositToVault() public {
        Vault governorOZVault = Vault(addresses.getAddress("GOVERNOR_OZ_VAULT"));
        address governorOZTimelock = addresses.getAddress("GOVERNOR_OZ_TIMELOCK");
        address governanceToken = addresses.getAddress("GOVERNOR_OZ_VAULT_TOKEN");
        (uint256 prevDeposit, ) = governorOZVault.deposits(governanceToken, governorOZTimelock);
        uint256 depositAmount = 100;

        vm.startPrank(governorOZTimelock);
        Token(governanceToken).mint(governorOZTimelock, depositAmount);
        Token(governanceToken).approve(address(governorOZVault), depositAmount);
        governorOZVault.deposit(address(governanceToken), depositAmount);

        (uint256 amount, ) = governorOZVault.deposits(governanceToken, governorOZTimelock);
        assertTrue(
            amount == (prevDeposit + depositAmount),
            "Token should be deposited"
        );
    }
}
