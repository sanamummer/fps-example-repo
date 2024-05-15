// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {GovernorOZProposal} from "@forge-proposal-simulator/src/proposals/GovernorOZProposal.sol";

import {ITimelockController} from "@forge-proposal-simulator/src/interface/ITimelockController.sol";
import {IProxy} from "@forge-proposal-simulator/src/interface/IProxy.sol";
import {IGovernor, IGovernorTimelockControl, IGovernorVotes} from "@forge-proposal-simulator/src/interface/IGovernor.sol";
import {IProxyAdmin} from "@forge-proposal-simulator/src/interface/IProxyAdmin.sol";

abstract contract ArbitrumProposal is GovernorOZProposal {
    address public constant RETRYABLE_TICKET_MAGIC =
        0xa723C008e76E379c55599D2E4d93879BeaFDa79C;

    enum ProposalExecutionChain {
        ETH,
        ARB_ONE,
        ARB_NOVA
    }

    ProposalExecutionChain internal executionChain;

    /// @notice Arbitrum proposals should have a single action
    function _validateActions() internal view override {
        uint256 actionsLength = actions.length;
        require(
            actionsLength == 1,
            "Arbitrum proposals must have a single action"
        );

        require(actions[0].target != address(0), "Invalid target for proposal");
        /// if there are no args and no eth, the action is not valid
        require(
            (actions[0].arguments.length == 0 && actions[0].value > 0) ||
                actions[0].arguments.length > 0,
            "Invalid arguments for proposal"
        );

        // Value is ignored on L2 proposals
        if (executionChain == ProposalExecutionChain.ARB_ONE) {
            require(actions[0].value == 0, "Value must be 0 for L2 execution");
        }
    }

    /// @notice get proposal actions
    /// @dev Arbitrum proposals must have a single action which must be a call
    /// to ArbSys address with the l1 timelock schedule calldata
    function getProposalActions()
        public
        view
        override
        returns (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory arguments
        )
    {
        _validateActions();

        // TODO add lint to CI

        uint256 minDelay = ITimelockController(
            addresses.getAddress("ARBITRUM_L1_TIMELOCK")
        ).getMinDelay();

        bytes memory innerCalldata = abi.encodeWithSelector(
            ITimelockController.schedule.selector,
            // if the action is to be executed on l1, the target is the actual
            // target, otherwise it is the magic value that tells that the
            // proposal must be relayed back to l2
            executionChain == ProposalExecutionChain.ETH
                ? actions[0].target
                : RETRYABLE_TICKET_MAGIC,
            actions[0].value,
            executionChain == ProposalExecutionChain.ETH
                ? actions[0].arguments
                : abi.encode( // these are the retryable data params
                        // the inbox we want to use, should be arb one or nova
                        // inbox. getAddress get the correct one based on the execution chain
                        addresses.getAddress("ARBITRUM_L2_INBOX"),
                        addresses.getAddress("ARBITRUM_L2_UPGRADE_EXECUTOR"), // the upgrade executor on the l2 network
                        0, // no value in this upgrade
                        0, // max gas - will be filled in when the retryable is actually executed
                        0, // max fee per gas - will be filled in when the retryable is actually executed
                        actions[0].arguments // calldata created on the build function
                    ),
            bytes32(0), // no predecessor
            keccak256(abi.encodePacked(description())), // prop description
            minDelay // delay for this proposal
        );

        targets = new address[](1);
        values = new uint256[](1);
        arguments = new bytes[](1);

        // Arbitrum proposals target must be the ArbSys precompiled address
        targets[0] = addresses.getAddress("ARBITRUM_SYS");
        values[0] = 0;
        arguments[0] = innerCalldata;
    }

    function simulate() public override {
        // First part of Arbitrum Governance proposal path follow the OZ
        // Governor with TimelockController extension
        super.simulate();
    }
}
