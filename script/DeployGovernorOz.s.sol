pragma solidity ^0.8.0;

import "@forge-std/Script.sol";
import "forge-std/console.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {TimelockController} from "@openzeppelin/governance/TimelockController.sol";

import {MockERC20Votes} from "src/mocks/governor-oz/MockERC20Votes.sol";
import {MockGovernorOz} from "src/mocks/governor-oz/MockGovernorOz.sol";

contract DeployGovernorOz is Script {
    function run() public virtual {
        Addresses addresses = new Addresses("./addresses/Addresses.json");

        // Get proposer and executor addresses
        address dev = addresses.getAddress("DEPLOYER_EOA");

        // Create arrays of addresses to pass to the TimelockController constructor
        address[] memory proposers = new address[](1);
        proposers[0] = dev;
        address[] memory executors = new address[](1);
        executors[0] = address(0);

        vm.startBroadcast();
        // Deploy a new TimelockController
        TimelockController timelock = new TimelockController(60, proposers, executors, dev);

        // Deploy the governance token
        MockERC20Votes govToken = new MockERC20Votes("Governance Token", "GOV");

        govToken.mint(msg.sender, 1e21);

        // Deploy MockGovernorOz
        MockGovernorOz governor = new MockGovernorOz(
            govToken, // governance token
            timelock // timelock
        );

        // add propose and execute role for governor
        timelock.grantRole(keccak256("PROPOSER_ROLE"), address(governor));

        vm.stopBroadcast();

        // Update GOVERNOR_OZ address
        addresses.changeAddress("GOVERNOR_OZ", address(governor), true);

        // Update GOVERNOR_OZ_TIMELOCK address
        addresses.changeAddress("GOVERNOR_OZ_TIMELOCK", address(timelock), true);

        // Update GOVERNOR_OZ_GOVERNANCE_TOKEN address
        addresses.changeAddress("GOVERNOR_OZ_GOVERNANCE_TOKEN", address(govToken), true);

        addresses.printJSONChanges();
    }
}
