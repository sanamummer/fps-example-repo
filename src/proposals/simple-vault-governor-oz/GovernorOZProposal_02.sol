// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {GovernorOZProposal} from "@forge-proposal-simulator/src/proposals/GovernorOZProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";

contract GovernorOZProposal_02 is GovernorOZProposal {
    function name() public pure override returns (string memory) {
        return "GOVERNOR_OZ_PROPOSAL_02";
    }

    function description() public pure override returns (string memory) {
        return "Governor oz proposal mock 2";
    }

    function run() public override {
        primaryForkId = vm.createFork("sepolia");
        vm.selectFork(primaryForkId);

        setAddresses(
            new Addresses(
                vm.envOr("ADDRESSES_PATH", string("addresses/Addresses.json"))
            )
        );
        vm.makePersistent(address(addresses));

        setGovernor(addresses.getAddress("GOVERNOR_OZ"));

        super.run();
    }

    function build()
        public
        override
        buildModifier(addresses.getAddress("GOVERNOR_OZ_TIMELOCK"))
    {
        /// STATICCALL -- not recorded for the run stage
        address timelock = addresses.getAddress("GOVERNOR_OZ_TIMELOCK");
        Vault governorOZVault = Vault(addresses.getAddress("GOVERNOR_OZ_VAULT"));
        address token = addresses.getAddress("GOVERNOR_OZ_VAULT_TOKEN");
        (uint256 amount, ) = governorOZVault.deposits(address(token), timelock);

        /// CALLS -- mutative and recorded
        governorOZVault.withdraw(token, payable(timelock), amount);
    }

    function validate() public override {
        Vault governorOZVault = Vault(addresses.getAddress("GOVERNOR_OZ_VAULT"));
        Token token = Token(addresses.getAddress("GOVERNOR_OZ_VAULT_TOKEN"));

        address timelock = addresses.getAddress("GOVERNOR_OZ_TIMELOCK");

        uint256 balance = token.balanceOf(address(governorOZVault));
        assertEq(balance, 0);

        (uint256 amount, ) = governorOZVault.deposits(
            address(token),
            address(timelock)
        );
        assertEq(amount, 0);

        assertEq(token.balanceOf(address(timelock)), 10_000_000e18);
    }
}
