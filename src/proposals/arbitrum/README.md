# Arbitrum Proposal

## Governance Overview

Arbitrum utilizes an OpenZeppelin Governor and an OpenZeppelin Timelock on
Arbitrum One (referred to as L2), along with a customized OpenZeppelin Timelock
on Ethereum (referred to as L1).

### L2 Governor

Proposals must be submitted to the Governor on L2. The calldata of the proposal should be a call to the schedule function of the Timelock on Ethereum, with the target being the ArbSys precompiled contract.

### L2 Arbitrum

If a proposal passes the L2 Governor, it must be queued and executed on the L2 Timelock, which requires a minimum delay of three days before execution.

### L1 Arbitrum

The execution involves making a call to the ArbSys precompiled contract on L2,
which requires a one-week delay to generate the Merkle root. Once the Merkle
root is generated, anyone can call the Arbitrum Bridge on L1 with the proof to
submit the proposal to the L1 Timelock.

Once the proposal is scheduled on the L1 Timelock, it requires a three-day delay before it becomes executable. Although only the Arbitrum Bridge can schedule proposals, anyone can execute them.

If the target is an L1 contract, the proposal follows the standard OpenZeppelin Timelock path. For L2 proposals, identified by the target being a Retryable Ticket Magic address, a call to the L1 inbox generates the L2 ticket. Once it is bridged to L2, anyone can execute the ticket.

## Proposal Overview

As detailed in the [Arbitrum Governance Documentation](https://github.com/ArbitrumFoundation/governance/blob/main/docs), proposal are executed through pre-deployed Governance Action Contracts (GACs). Arbitrum has various GACs deployed for different actions, which can be found [here](https://github.com/ArbitrumFoundation/governance/tree/main/src/gov-action-contracts).

For Transparent Upgradeable Proxy Contracts managed by the Proxy Admin, the GAC must perform a call to the proxy admin, passing the proxy address and the new implementation address.

## Current Proposal Creation Process

## Proposal Creation Examples Using FPS

We have developed an [ArbitrumProposal.sol](./ArbitrumProposal.sol) contract
that extends the FPS GovernorOZProposal to showcase the FPS capabilities. FPS
allows the creation of declarative proposals that undergo not only code review
but also integration tests simulating the entire proposal lifecycle. This
includes L2 submission, L1 settlement, and execution on L1 if is the case, or on L2 if the target is an L2 contract. FPS streamlines the process by eliminating the need for manual testing and calldata crafting. Calldata is programmatically generated and then run. Prior to on-chain submission, each proposal undergoes testing against the Arbitrum Integration Test Suite in a mainnet forked environment to ensure it functions as intended and is safe to execute. Additionally, this framework allows testing not only of governance proposals but of their associated deployment scripts.

### ArbitrumProposal Contract Functions Overview

-   `afterDeployMock`: function provided by the FPS can be
    used to mock any contract when direct interaction with the on-chain state is
    not possible for running the proposal lifecycle simulation. The Merkle tree
    generation part of the proposal cycle cannot be simulated because it is an
    off-chain process carried out in Golang. Therefore, it is necessary to mock
    the active outbox on the Arbitrum Bridge to return the L2 Timelock on the
    `l2ToL1Sender` function. Additionally, Foundry does not support interactions
    with precompiled contracts, so the ArbSys contract must also be mocked.

-   `validateActions`: FPS internal function that is automatically called after
    the build function (more information about the build function is provided
    below). Arbitrum proposals should only contain a single action - the call to
    the ArbSys precompiled contract. Therefore, the 'validateActions' function is
    overridden to ensure that only one action is present.
-   `getScheduleTimelockCalldata`: function used to generate the calldata
    for the schedule function of the Timelock on Ethereum.

-   `getProposalActions`: function used to generate the actions for the
    proposal. In this case, it generates a single action to call the ArbSys
    precompiled contract. This is a utility function that is used by other
    functions like `simulate` and GovernorOzProposal `getCalldata`.
-   `simulate`: this function is used to simulate the proposal lifecycle. The
    first part of the simulation follows the standard OZ Governor proposal path by
    calling `super.simulate()`. FPS leverages Foundry to simulate proposing,
    voting, queuing on the L2 timelock, and finally executing. Once the proposal
    is executed by the L2 Timelock, ArbitrumProposal simulates the L1 settlement
    by calling the L1 Timelock using the Bridge as the sender to schedule the
    proposal. Finally, the proposal is executed on L1 and if the target is an L2 contract, the calldata is retrievable from the logs and it's executed on L2, which can be either Arbitrum One or Arbitrum Nova.
