pragma solidity ^0.8.0;

import { TimelockProposal } from "@forge-proposal-simulator/src/proposals/TimelockProposal.sol";
import { ITimelockController } from "@forge-proposal-simulator/src/interfaces/ITimelockController.sol";
import { Addresses } from "@forge-proposal-simulator/addresses/Addresses.sol";
import { Vault } from "@forge-proposal-simulator/mocks/Vault.sol";
import { Token } from "@forge-proposal-simulator/mocks/Token.sol";

contract MockTimelockProposal is TimelockProposal {
    function name() public pure override returns (string memory) {
        return "TIMELOCK_MOCK";
    }

    function description() public pure override returns (string memory) {
        return "Timelock proposal mock";
    }

    function run() public override {
        timelock = ITimelockController(
            addresses.getAddress("PROTOCOL_TIMELOCK")
        );

        super.run();
    }

    function deploy() public override {
        if (!addresses.isAddressSet("TIMELOCK_VAULT")) {
            Vault timelockVault = new Vault();

            addresses.addAddress(
                "TIMELOCK_VAULT",
                address(timelockVault),
                true
            );

            timelockVault.transferOwnership(address(timelock));
        }

        if (!addresses.isAddressSet("TIMELOCK_TOKEN")) {
            Token token = new Token();
            addresses.addAddress("TIMELOCK_TOKEN", address(token), true);

            token.transferOwnership(address(timelock));

            // During forge script execution, the deployer of the contracts is
            // the DEPLOYER_EOA. However, when running through forge test, the deployer of the contracts is this contract.
            uint256 balance = token.balanceOf(address(this)) > 0
                ? token.balanceOf(address(this))
                : token.balanceOf(addresses.getAddress("DEPLOYER_EOA"));

            token.transfer(address(timelock), balance);
        }
    }

    function build() public override buildModifier(address(timelock)) {
        /// STATICCALL -- not recorded for the run stage
        address timelockVault = addresses.getAddress("TIMELOCK_VAULT");
        address token = addresses.getAddress("TIMELOCK_TOKEN");
        uint256 balance = Token(token).balanceOf(address(timelock));

        Vault(timelockVault).whitelistToken(token, true);

        /// CALLS -- mutative and recorded
        Token(token).approve(timelockVault, balance);
        Vault(timelockVault).deposit(token, balance);
    }

    function simulate() public override {
        /// Call parent simulate function to check if there are actions to execute
        super.simulate();

        address proposer = addresses.getAddress("TIMELOCK_PROPOSER");

        _simulateActions(proposer, proposer);
    }

    function validate() public override {
        Vault timelockVault = Vault(addresses.getAddress("TIMELOCK_VAULT"));
        Token token = Token(addresses.getAddress("TIMELOCK_TOKEN"));

        uint256 balance = token.balanceOf(address(timelockVault));
        (uint256 amount, ) = timelockVault.deposits(
            address(token),
            address(timelock)
        );
        assertEq(amount, balance);

        assertEq(timelockVault.owner(), address(timelock));
        assertTrue(timelockVault.tokenWhitelist(address(token)));
        assertFalse(timelockVault.paused());

        assertEq(token.owner(), address(timelock));
        assertEq(token.balanceOf(address(timelockVault)), token.totalSupply());
    }
}