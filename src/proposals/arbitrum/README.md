# Arbitrum Proposal

## Governance Overview

Arbitrum utilizes an OpenZeppelin Governor and an OpenZeppelin Timelock on
Arbitrum One (referred to as L2), along with a customized OpenZeppelin Timelock
on Ethereum (referred to as L1).

### L2 Governor

Proposals must be submitted to the Governor on L2. The calldata of the proposal should be a call to the schedule function of the Timelock on Ethereum, with the target being the ArbSys precompiled contract.

### L2 Arbitrum

If a proposal passes the Arbitrum One Governor, it must be queued and executed on the Arbitrum One Timelock, which requires a minimum delay of three days before execution.

### L1 Arbitrum

The execution involves making a call to the ArbSys precompiled contract on Arbitrum One, which requires a one-week delay to generate the Merkle root. Once the Merkle root is generated, anyone can call the Arbitrum Bridge on L1 with the proof to submit the proposal to the Ethereum Timelock.

Once the proposal is scheduled on the Ethereum Timelock, it requires a three-day delay before it becomes executable. Although only the Arbitrum Bridge can schedule proposals, anyone can execute them.

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
includes L2 submission, L1 settlement, and execution on L1 if is the case, or on L2 if the target is an L2 contract. FPS streamlines the process by eliminating the need for manual testing and calldata crafting, handling all complexities. Prior to on-chain submission, each proposal undergoes testing against the Arbitrum Integration Test in a forked mainnet environment to ensure it functions as intended and is safe to execute.

### ArbitrumProposal Contract Functions Overview

-   `afterDeployMock`:
