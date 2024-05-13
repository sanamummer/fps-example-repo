pragma solidity ^0.8.0;

import { MultisigProposal } from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";
import { Addresses } from "@forge-proposal-simulator/addresses/Addresses.sol";
import { Vault } from "mocks/Vault.sol";
import { Token } from "mocks/Token.sol";
import {console} from "@forge-std/console.sol";

contract MultisigProposal_02 is MultisigProposal {
    function name() public pure override returns (string memory) {
        return "MULTISIG_MOCK_02";
    }

    function description() public pure override returns (string memory) {
        return "Multisig proposal mock 2";
    }
    /// Todo: set address
    function run() public override {
        primaryForkId = vm.createFork("sepolia");

        console.log("Addresses ->", address(addresses));

        super.run();
    }

    function build()
        public
        override
        buildModifier(addresses.getAddress("DEV_MULTISIG"))
    {
        address multisig = addresses.getAddress("DEV_MULTISIG");

        /// STATICCALL -- not recorded for the run stage
        Vault multisigVault = Vault(addresses.getAddress("MULTISIG_VAULT"));
        address token = addresses.getAddress("MULTISIG_TOKEN");
        (uint256 amount, ) = multisigVault.deposits(
            address(token),
            multisig
        );

        /// CALLS -- mutative and recorded
        multisigVault.withdraw(token, payable(multisig), amount);
    }

    function simulate() public override {
        address multisig = addresses.getAddress("DEV_MULTISIG");

        /// Dev is proposer and executor
        _simulateActions(multisig);
    }
    /// Todo: check balance multisig
    function validate() public override {
        Vault timelockVault = Vault(addresses.getAddress("MULTISIG_VAULT"));
        Token token = Token(addresses.getAddress("MULTISIG_TOKEN"));
        address multisig = addresses.getAddress("DEV_MULTISIG");

        uint256 balance = token.balanceOf(address(timelockVault));
        assertEq(balance, 0);

        (uint256 amount, ) = timelockVault.deposits(address(token), multisig);
        assertEq(amount, 0);
    }
}
