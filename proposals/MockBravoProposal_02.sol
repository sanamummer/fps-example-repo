// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {GovernorBravoProposal} from "@forge-proposal-simulator/src/proposals/GovernorBravoProposal.sol";
import {IGovernorAlpha} from "@forge-proposal-simulator/src/interface/IGovernorBravo.sol";
import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {Vault} from "proposals/utils/Vault.sol";
import {Token} from "proposals/utils/Token.sol";

contract MockBravoProposal_02 is GovernorBravoProposal {
    function name() public pure override returns (string memory) {
        return "BRAVO_MOCK_2";
    }

    function description() public pure override returns (string memory) {
        return "Bravo proposal mock 2";
    }

    function run() public override {
        primaryForkId = vm.createFork("sepolia");
        vm.selectFork(primaryForkId);

        addresses = new Addresses(
            vm.envOr("ADDRESSES_PATH", string("./addresses/Addresses.json"))
        );
        vm.makePersistent(address(addresses));

        governor = IGovernorAlpha(addresses.getAddress("PROTOCOL_GOVERNOR"));

        super.run();
    }

    function build()
        public
        override
        buildModifier(addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO"))
    {
        /// STATICCALL -- not recorded for the run stage
        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO");
        Vault bravoVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        address token = addresses.getAddress("BRAVO_VAULT_TOKEN");
        uint256 balance = Token(token).balanceOf(timelock);
        (uint256 amount, ) = bravoVault.deposits(
            address(token),
            timelock
        );

        /// CALLS -- mutative and recorded
        bravoVault.withdraw(token, timelock, amount);
    }

    function simulate() public override {        
        /// Call parent simulate function to check if there are actions to execute
        super.simulate();

        address governanceToken = addresses.getAddress(
            "PROTOCOL_GOVERNANCE_TOKEN"
        );
        address proposer = addresses.getAddress("DEPLOYER_EOA");

        /// Dev is proposer and executor
        _simulateActions(governanceToken, proposer);
    }

    function validate() public override {
        Vault bravoVault = Vault(addresses.getAddress("BRAVO_VAULT"));
        Token token = Token(addresses.getAddress("BRAVO_VAULT_TOKEN"));

        address timelock = addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO");

        uint256 balance = token.balanceOf(address(bravoVault));
        assertEq(balance, 0);
        
        (uint256 amount, ) = bravoVault.deposits(
            address(token),
            address(timelock)
        );
        assertEq(amount, 0);
    }
}
