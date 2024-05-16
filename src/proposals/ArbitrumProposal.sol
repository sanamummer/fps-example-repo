// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {Vm} from "@forge-std/Vm.sol";

import {Addresses} from "@forge-proposal-simulator/addresses/Addresses.sol";
import {GovernorOZProposal} from "@forge-proposal-simulator/src/proposals/GovernorOZProposal.sol";

import {ITimelockController} from "@forge-proposal-simulator/src/interface/ITimelockController.sol";
import {IProxy} from "@forge-proposal-simulator/src/interface/IProxy.sol";
import {IGovernor, IGovernorTimelockControl, IGovernorVotes} from "@forge-proposal-simulator/src/interface/IGovernor.sol";
import {IProxyAdmin} from "@forge-proposal-simulator/src/interface/IProxyAdmin.sol";
import {Address} from "@forge-proposal-simulator/utils/Address.sol";

import {MockArbSys} from "../mocks/MockArbSys.sol";
import {MockArbOutbox} from "../mocks/MockArbOutbox.sol";

abstract contract ArbitrumProposal is GovernorOZProposal {
    using Address for address;

    address public constant RETRYABLE_TICKET_MAGIC =
        0xa723C008e76E379c55599D2E4d93879BeaFDa79C;

    enum ProposalExecutionChain {
        ETH,
        ARB_ONE,
        ARB_NOVA
    }

    ProposalExecutionChain internal executionChain;

    /// @notice arbitrum proposals must be settled on the l1 network
    uint256 public ethForkId;

    /// @notice set eth fork id
    function setEthForkId(uint256 _forkId) public {
        ethForkId = _forkId;
    }

    /// @notice mock arb sys precompiled contract
    function afterDeployMock() public override {
        address arbsys = address(new MockArbSys());
        vm.makePersistent(arbsys);

        vm.etch(addresses.getAddress("ARBITRUM_SYS"), address(arbsys).code);

        // switch to mainnet fork to mock arb outbox
        vm.selectFork(ethForkId);
        address mockOutbox = address(new MockArbOutbox());

        vm.store(
            addresses.getAddress("ARBITRUM_BRIDGE"),
            bytes32(uint256(5)),
            bytes32(uint256(uint160(mockOutbox)))
        );

        vm.selectFork(primaryForkId);
    }

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

    function getScheduleTimelockCaldata()
        public
        returns (bytes memory scheduleCalldata)
    {
        vm.selectFork(ethForkId);
        uint256 minDelay = ITimelockController(
            addresses.getAddress("ARBITRUM_L1_TIMELOCK")
        ).getMinDelay();

        address inbox;

        if (executionChain == ProposalExecutionChain.ARB_ONE) {
            inbox = addresses.getAddress("ARBITRUM_ONE_INBOX");
        } else if (executionChain == ProposalExecutionChain.ARB_NOVA) {
            inbox = addresses.getAddress("ARBITRUM_NOVA_INBOX");
        }

        vm.selectFork(primaryForkId);

        scheduleCalldata = abi.encodeWithSelector(
            ITimelockController.schedule.selector,
            // if the action is to be executed on l1, the target is the actual
            // target, otherwise it is the magic value that tells that the
            // proposal must be relayed back to l2
            executionChain == ProposalExecutionChain.ETH
                ? actions[0].target
                : RETRYABLE_TICKET_MAGIC, // target
            actions[0].value, // value
            executionChain == ProposalExecutionChain.ETH
                ? actions[0].arguments
                : abi.encode( // these are the retryable data params
                        // the inbox we want to use, should be arb one or nova
                        inbox,
                        addresses.getAddress("ARBITRUM_L2_UPGRADE_EXECUTOR"), // the upgrade executor on the l2 network
                        0, // no value in this upgrade
                        0, // max gas - will be filled in when the retryable is actually executed
                        0, // max fee per gas - will be filled in when the retryable is actually executed
                        actions[0].arguments // calldata created on the build function
                    ),
            bytes32(0), // no predecessor
            keccak256(abi.encodePacked(description())), // salt is prop description
            minDelay // delay for this proposal
        );
    }

    /// @notice get proposal actions
    /// @dev Arbitrum proposals must have a single action which must be a call
    /// to ArbSys address with the l1 timelock schedule calldata
    function getProposalActions()
        public
        override
        returns (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory arguments
        )
    {
        _validateActions();

        // inner calldata must be a call to schedule on L1Timelock
        bytes memory innerCalldata = getScheduleTimelockCaldata();

        targets = new address[](1);
        values = new uint256[](1);
        arguments = new bytes[](1);

        bytes memory callData = abi.encodeWithSelector(
            MockArbSys.sendTxToL1.selector,
            addresses.getAddress("ARBITRUM_L1_TIMELOCK", 1),
            innerCalldata
        );

        // Arbitrum proposals target must be the ArbSys precompiled address
        targets[0] = addresses.getAddress("ARBITRUM_SYS");
        values[0] = 0;
        arguments[0] = callData;
    }

    function simulate() public override {
        // First part of Arbitrum Governance proposal path follows the OZ
        // Governor with TimelockController extension
        super.simulate();

        // Second part of Arbitrum Governance proposal path is the proposal
        // settlement on the L1 network
        bytes memory scheduleCalldata = getScheduleTimelockCaldata();

        // switch fork to mainnet
        vm.selectFork(ethForkId);

        // prank as the bridge
        vm.startPrank(addresses.getAddress("ARBITRUM_BRIDGE"));

        address l1TimelockAddress = addresses.getAddress(
            "ARBITRUM_L1_TIMELOCK"
        );

        // Start recording logs so we can create the execute calldata
        vm.recordLogs();

        // Call the schedule function on the L1 timelock
        l1TimelockAddress.functionCall(scheduleCalldata);

        // Stop recording logs
        Vm.Log[] memory entries = vm.getRecordedLogs();

        // Get the execute parameters from schedule call logs
        (
            address target,
            uint256 value,
            bytes memory data,
            bytes32 predecessor,

        ) = abi.decode(
                entries[0].data,
                (address, uint256, bytes, bytes32, uint256)
            );

        // warp to the future to execute the proposal
        ITimelockController timelock = ITimelockController(l1TimelockAddress);
        uint256 minDelay = timelock.getMinDelay();

        vm.warp(block.timestamp + minDelay);

        // execute the proposal
        timelock.execute(
            target,
            value,
            data,
            predecessor,
            keccak256(abi.encodePacked(description()))
        );
    }
}
