pragma solidity ^0.8.0;

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {MultisigProposal} from "@forge-proposal-simulator/src/proposals/MultisigProposal.sol";

import {MockGovernorAlpha} from "src/mocks/bravo/MockGovernorAlpha.sol";
import {Timelock} from "src/mocks/bravo/Timelock.sol";
import {GovernorBravoDelegate} from "src/mocks/bravo/GovernorBravoDelegate.sol";

/// @notice Governor Bravo initialization contract
/// DO_PRINT=false DO_BUILD=false DO_DEPLOY=true DO_VALIDATE=true forge script script/InitializeBravo.s.sol:InitializeBravo --fork-url sepolia -vvvvv
contract InitializeBravo is MultisigProposal {
    function name() public pure override returns (string memory) {
        return "INITIALIZE_GOVERNOR_BRAVO";
    }

    function description() public pure override returns (string memory) {
        return "Initialize Governor BRAVO contract";
    }

    function deploy() public override {
        address governor = addresses.getAddress("PROTOCOL_GOVERNOR");

        address payable timelock = payable(
            addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO")
        );

        // Deploy mock GovernorAlpha
        address govAlpha = address(new MockGovernorAlpha());

        Timelock(timelock).executeTransaction(
            timelock,
            0,
            "",
            abi.encodeWithSignature(
                "setPendingAdmin(address)",
                address(governor)
            ),
            vm.envUint("ETA")
        );

        // Initialize GovernorBravo
        GovernorBravoDelegate(governor)._initiate(govAlpha);

        addresses.changeAddress("PROTOCOL_GOVERNOR_ALPHA", govAlpha, true);

        addresses.printJSONChanges();
    }

    function run() public override {
        setAddresses(new Addresses("./addresses/Addresses.json"));

        super.run();
    }

    function validate() public override {
        Timelock timelock = Timelock(payable(addresses.getAddress("PROTOCOL_TIMELOCK_BRAVO")));

        // ensure governor bravo is set as timelock admin
        assertEq(timelock.admin(), addresses.getAddress("PROTOCOL_GOVERNOR"));
    }
}
