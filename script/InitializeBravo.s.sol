pragma solidity ^0.8.0;

import "@forge-std/Script.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";

import {MockGovernorAlpha} from "src/mocks/MockGovernorAlpha.sol";
import {Timelock} from "src/mocks/bravo/Timelock.sol";
import {GovernorBravoDelegate} from "src/mocks/bravo/GovernorBravoDelegate.sol";

contract DeployGovernorBravo is Script {
    function run() public virtual {
        Addresses addresses = new Addresses("./addresses/Addresses.json");

        address governor = addresses.getAddress("PROTOCOL_GOVERNOR");

        address payable timelock = payable(addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO"));

        vm.startBroadcast();

        // Deploy mock GovernorAlpha
        address govAlpha = address(new MockGovernorAlpha());

        Timelock(timelock).executeTransaction(
            timelock, 0, "", abi.encodeWithSignature("setPendingAdmin(address)", address(governor)), vm.envUint("ETA")
        );

        // Initialize GovernorBravo
        GovernorBravoDelegate(governor)._initiate(govAlpha);

        vm.stopBroadcast();

        addresses.changeAddress("PROTOCOL_GOVERNOR_ALPHA", govAlpha, true);

        addresses.printJSONChanges();
    }
}