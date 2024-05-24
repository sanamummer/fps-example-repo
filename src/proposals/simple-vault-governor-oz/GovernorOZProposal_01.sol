// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {GovernorOZProposal} from "@forge-proposal-simulator/src/proposals/GovernorOZProposal.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {Vault} from "src/mocks/vault/Vault.sol";
import {Token} from "src/mocks/vault/Token.sol";

contract GovernorOZProposal_01 is GovernorOZProposal {
    function name() public pure override returns (string memory) {
        return "GOVERNOR_OZ_PROPOSAL";
    }

    function description() public pure override returns (string memory) {
        return "Governor oz proposal mock 1";
    }

    function run() public override {
        setPrimaryForkId(vm.createSelectFork("sepolia"));

        setAddresses(
            new Addresses(
                vm.envOr("ADDRESSES_PATH", string("addresses/Addresses.json"))
            )
        );

        setGovernor(addresses.getAddress("GOVERNOR_OZ"));

        super.run();
    }

    function deploy() public override {
        address owner = addresses.getAddress("GOVERNOR_OZ_TIMELOCK");
        if (!addresses.isAddressSet("GOVERNOR_OZ_VAULT")) {
            Vault governorOZVault = new Vault();

            addresses.addAddress("GOVERNOR_OZ_VAULT", address(governorOZVault), true);
            governorOZVault.transferOwnership(owner);
        }

        if (!addresses.isAddressSet("GOVERNOR_OZ_VAULT_TOKEN")) {
            Token token = new Token();
            addresses.addAddress("GOVERNOR_OZ_VAULT_TOKEN", address(token), true);
            token.transferOwnership(owner);

            // During forge script execution, the deployer of the contracts is
            // the DEPLOYER_EOA. However, when running through forge test, the deployer of the contracts is this contract.
            uint256 balance = token.balanceOf(address(this)) > 0
                ? token.balanceOf(address(this))
                : token.balanceOf(addresses.getAddress("DEPLOYER_EOA"));

            token.transfer(address(owner), balance);
        }
    }

    function build()
        public
        override
        buildModifier(addresses.getAddress("GOVERNOR_OZ_TIMELOCK"))
    {
        /// STATICCALL -- not recorded for the run stage
        address governorOZVault = addresses.getAddress("GOVERNOR_OZ_VAULT");
        address token = addresses.getAddress("GOVERNOR_OZ_VAULT_TOKEN");
        uint256 balance = Token(token).balanceOf(
            addresses.getAddress("GOVERNOR_OZ_TIMELOCK")
        );

        /// CALLS -- mutative and recorded
        Vault(governorOZVault).whitelistToken(token, true);
        Token(token).approve(governorOZVault, balance);
        Vault(governorOZVault).deposit(token, balance);
    }

    function validate() public override {
        Vault governorOZVault = Vault(addresses.getAddress("GOVERNOR_OZ_VAULT"));
        Token token = Token(addresses.getAddress("GOVERNOR_OZ_VAULT_TOKEN"));

        address timelock = addresses.getAddress("GOVERNOR_OZ_TIMELOCK");

        uint256 balance = token.balanceOf(address(governorOZVault));
        (uint256 amount, ) = governorOZVault.deposits(
            address(token),
            address(timelock)
        );
        assertEq(amount, balance);

        assertTrue(governorOZVault.tokenWhitelist(address(token)));

        assertEq(token.balanceOf(address(governorOZVault)), token.totalSupply());

        assertEq(token.totalSupply(), 10_000_000e18);

        assertEq(token.owner(), address(timelock));

        assertEq(governorOZVault.owner(), address(timelock));

        assertFalse(governorOZVault.paused());
    }
}
