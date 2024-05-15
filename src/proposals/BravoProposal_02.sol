// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {GovernorBravoProposal} from "@forge-proposal-simulator/src/proposals/GovernorBravoProposal.sol";
import {IGovernorBravo} from "@forge-proposal-simulator/src/interface/IGovernorBravo.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {Vault} from "src/mocks/Vault.sol";
import {Token} from "src/mocks/Token.sol";

contract BravoProposal_02 is GovernorBravoProposal {
    function name() public pure override returns (string memory) {
        return "BRAVO_MOCK_02";
    }

    function description() public pure override returns (string memory) {
        return "Bravo proposal mock 2";
    }

    function run() public override {
        primaryForkId = vm.createFork("sepolia");
        vm.selectFork(primaryForkId);

        setAddresses(new Addresses(vm.envOr("ADDRESSES_PATH", string("addresses/Addresses.json"))));
        vm.makePersistent(address(addresses));

        setGovernor(addresses.getAddress("PROTOCOL_GOVERNOR"));

        super.run();
    }

    function build() public override buildModifier(addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO")) {
        /// STATICCALL -- not recorded for the run stage
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO");
        Vault bravoVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        address token = addresses.getAddress("BRAVO_VAULT_TOKEN");
        (uint256 amount,) = bravoVault.deposits(address(token), timelock);

        /// CALLS -- mutative and recorded
        bravoVault.withdraw(token, payable(timelock), amount);
    }

    function validate() public override {
        Vault bravoVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        Token token = Token(addresses.getAddress("BRAVO_VAULT_TOKEN"));

        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO");

        uint256 balance = token.balanceOf(address(bravoVault));
        assertEq(balance, 0);

        (uint256 amount,) = bravoVault.deposits(address(token), address(timelock));
        assertEq(amount, 0);

        assertEq(token.balanceOf(address(timelock)), 10_000_000e18);
    }
}
