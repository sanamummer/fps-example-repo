pragma solidity ^0.8.0;

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {MultisigProposal} from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";

import {TimelockController} from "@openzeppelin/governance/TimelockController.sol";

import {MockERC20Votes} from "src/mocks/governor-oz/MockERC20Votes.sol";
import {MockGovernorOz} from "src/mocks/governor-oz/MockGovernorOz.sol";

/// @notice Governor OZ deployment contract
/// DO_PRINT=false DO_BUILD=false DO_DEPLOY=true DO_VALIDATE=true forge script script/DeployGovernorOZ.s.sol:DeployGovernorOZ --fork-url sepolia -vvvvv
contract DeployGovernorOZ is MultisigProposal {
    function name() public pure override returns (string memory) {
        return "GOVERNOR_OZ_DEPLOY";
    }

    function description() public pure override returns (string memory) {
        return "Deploy Governor OZ contract";
    }

    function deploy() public override {
        // Get proposer and executor addresses
        address dev = addresses.getAddress("DEPLOYER_EOA");

        // Create arrays of addresses to pass to the TimelockController constructor
        address[] memory proposers = new address[](1);
        proposers[0] = dev;
        address[] memory executors = new address[](1);
        executors[0] = address(0);

        // Deploy a new TimelockController
        TimelockController timelock = new TimelockController(60, proposers, executors, dev);

        // Deploy the governance token
        MockERC20Votes govToken = new MockERC20Votes("Governance Token", "GOV");

        govToken.mint(dev, 1e21);

        // Deploy MockGovernorOz
        MockGovernorOz governor = new MockGovernorOz(
            govToken, // governance token
            timelock // timelock
        );

        // add propose and execute role for governor
        timelock.grantRole(keccak256("PROPOSER_ROLE"), address(governor));

        // Update GOVERNOR_OZ address
        addresses.changeAddress("GOVERNOR_OZ", address(governor), true);

        // Update GOVERNOR_OZ_TIMELOCK address
        addresses.changeAddress("GOVERNOR_OZ_TIMELOCK", address(timelock), true);

        // Update GOVERNOR_OZ_GOVERNANCE_TOKEN address
        addresses.changeAddress("GOVERNOR_OZ_GOVERNANCE_TOKEN", address(govToken), true);

        addresses.printJSONChanges();
    }

    function run() public override {
        setAddresses(new Addresses("./addresses/Addresses.json"));

        super.run();
    }

    function validate() public override {
        MockERC20Votes govToken = MockERC20Votes(addresses.getAddress("GOVERNOR_OZ_GOVERNANCE_TOKEN"));

        // ensure governance token is minted to deployer address
        assertEq(govToken.balanceOf(addresses.getAddress("DEPLOYER_EOA")), 1e21);

        TimelockController timelock = TimelockController(payable(addresses.getAddress("GOVERNOR_OZ_TIMELOCK")));

        // ensure governor oz has been granted proposer role on timelock
        assertTrue(timelock.hasRole(keccak256("PROPOSER_ROLE"), addresses.getAddress("GOVERNOR_OZ")));
    }
}
