pragma solidity ^0.8.0;

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {GovernorBravoDelegator} from "@comp-governance/GovernorBravoDelegator.sol";
import {MultisigProposal} from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";

import {MockERC20Votes} from "src/mocks/bravo/MockERC20Votes.sol";
import {Timelock} from "src/mocks/bravo/Timelock.sol";
import {GovernorBravoDelegate} from "src/mocks/bravo/GovernorBravoDelegate.sol";

/// @notice Governor Bravo deployment contract
/// DO_PRINT=false DO_BUILD=false DO_DEPLOY=true DO_VALIDATE=true forge script script/DeployGovernorBravo.s.sol:DeployGovernorBravo --fork-url sepolia -vvvvv
contract DeployGovernorBravo is MultisigProposal {
    function name() public pure override returns (string memory) {
        return "GOVERNOR_BRAVO_DEPLOY";
    }

    function description() public pure override returns (string memory) {
        return "Deploy Governor BRAVO contract";
    }

    function deploy() public override {
        address deployer = addresses.getAddress("DEPLOYER_EOA");
        
        // Deploy and configure the timelock
        Timelock timelock = new Timelock(deployer, 1);

        // Deploy the governance token
        MockERC20Votes govToken = new MockERC20Votes("Governance Token", "GOV");

        govToken.mint(deployer, 1e21);

        // Deploy the GovernorBravoDelegate implementation
        GovernorBravoDelegate implementation = new GovernorBravoDelegate();

        // Deploy and configure the GovernorBravoDelegator
        GovernorBravoDelegator governor = new GovernorBravoDelegator(
            address(timelock), // timelock
            address(govToken), // governance token
            deployer, // admin
            address(implementation), // implementation
            60, // voting period
            1, // voting delay
            1e21 // proposal threshold
        );

        timelock.queueTransaction(
            address(timelock),
            0,
            "",
            abi.encodeWithSignature(
                "setPendingAdmin(address)",
                address(governor)
            ),
            block.timestamp + 180
        );

        // Update PROTOCOL_GOVERNOR address
        addresses.changeAddress("PROTOCOL_GOVERNOR", address(governor), true);

        // Update PROTOCOL_TIMELOCK_BRAVO address
        addresses.changeAddress(
            "PROTOCOL_TIMELOCK_BRAVO",
            address(timelock),
            true
        );

        addresses.changeAddress(
            "PROTOCOL_GOVERNANCE_TOKEN",
            address(govToken),
            true
        );

        addresses.printJSONChanges();
    }

    function run() public override {
        setAddresses(new Addresses("./addresses/Addresses.json"));

        super.run();
    }

    function validate() public override {
        MockERC20Votes govToken = MockERC20Votes(addresses.getAddress("PROTOCOL_GOVERNANCE_TOKEN"));

        // ensure governance token is minted to deployer address
        assertEq(govToken.balanceOf(addresses.getAddress("DEPLOYER_EOA")), 1e21);
    }
}