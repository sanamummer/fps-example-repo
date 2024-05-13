pragma solidity ^0.8.0;

import {Vault} from "mocks/Vault.sol";
import {Token} from "mocks/Token.sol";
import {TimelockPostProposalCheck} from "./TimelockPostProposalCheck.sol";

// @dev This test contract extends TimelockPostProposalCheck, granting it
// the ability to interact with state modifications effected by proposals
// and to work with newly deployed contracts, if applicable.
contract TimelockProposalIntegrationTest is TimelockPostProposalCheck {
    function test_addTokenToWhitelist() public {
        Vault timelockVault = Vault(addresses.getAddress("TIMELOCK_VAULT"));
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK");
        Token token = new Token();

        vm.prank(timelock);

        timelockVault.whitelistToken(address(token), true);

        assertTrue(timelockVault.tokenWhitelist(address(token)), "Token should be whitelisted");
    }

    function test_depositToVault() public {
        Vault timelockVault = Vault(addresses.getAddress("TIMELOCK_VAULT"));
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK");
        address token = addresses.getAddress("TIMELOCK_TOKEN");

        vm.startPrank(timelock);
        Token(token).mint(timelock, 100);
        Token(token).approve(address(timelockVault), 100);
        timelockVault.deposit(address(token), 100);

        (uint256 amount,) = timelockVault.deposits(address(token), timelock);
        assertTrue(amount == 1e25 + 100, "Token should be deposited");
    }
}
