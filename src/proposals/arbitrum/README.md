# Arbitrum Proposal

## Governance Overview

Arbitrum utilizes an OpenZeppelin Governor and an OpenZeppelin Timelock on
Arbitrum One (referred to as L2), along with a customized OpenZeppelin Timelock
on Ethereum (referred to as L1).

### L2 Governor

Proposals must be submitted to the Governor on L2. The calldata of the proposal should be a call to the schedule function of the Timelock on L1, with the target being the ArbSys precompiled contract.

### L2 Timelock

If a proposal passes the L2 Governor, it must be queued and executed on the L2 Timelock, which requires a minimum delay of three days before execution.

### L1 Timelock

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

Based on the Arbitrum governance documentation, the proposal creation process is as follows:

1. Create the GAC.
2. (Optional) Create unit tests for the GAC.
3. Deploy the GAC to the respective network.
4. Create the proposal calldata by running a script passing the provider, chain , GAC address and the json destination path.
5. Run simulation on the seatbelt repo. A PR with manual configuration is required.
6. Submit the proposal to the Governor.

## Proposal Creation Examples Using FPS

We have developed an [ArbitrumProposal.sol](./ArbitrumProposal.sol) contract
that extends the FPS GovernorOZProposal to showcase the this tool capabilities. FPS
allows the creation of declarative proposals that undergo not only code review
but also integration tests simulating the entire proposal lifecycle. This
includes L2 submission, L1 settlement, and execution on L1 if is the case, or on
L2 if the target is an L2 contract.

### ArbitrumProposal Functions

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
-   `simulate`: this function is used to simulate the proposal lifecycle from
    scheduling to execution. The first part of the simulation follows the standard OZ Governor proposal path by calling `super.simulate()`. FPS leverages Foundry to simulate proposing, voting, queuing on the L2 timelock, and finally executing. Once the proposal is executed by the L2 Timelock, ArbitrumProposal simulates the L1 settlement by calling the L1 Timelock using the Bridge as the sender to schedule the proposal. Finally, the proposal is executed on L1 and if the target is an L2 contract, the calldata is retrievable from the logs and it's executed on L2, which can be either Arbitrum One or Arbitrum Nova.

### Examples

We have developed two examples to illustrate how an Arbitrum proposal can be created and simulated using FPS. The first example is a proposal to upgrade the WETH Gateway contract on L2, while the second example is a proposal to upgrade the WETH Gateway contract on L1. Both examples inherit from the ArbitrumProposal. The only distinction between the two examples is the execution layer and target contracts.

-   `run`: This function is automatically called when running the proposal using `forge script`. It is essential to override the FPS run function to create the forks. The primary fork should always be the L2 fork, as it's where the proposal is submitted, and the secondary fork should be the L1 fork. We also set the governor address here. All the above functions and the ones described below are called from the `run` function, and FPS provides environment variables to skip any of them if needed.

-   `deploy`: function used to deploy the contracts needed for the
    proposal. In the examples, the WETH Gateway contract is deployed. We also
    deploy the GAC that will be used to upgrade the WETH Gateway contract, but
    this is not necessary if the GAC is pre-deployed.
-   `build`: function used to build the final proposal actions. Foundry is
    leveraged to record the actions, so plain Solidity code is used for building
    the actions.
-   `validate`: function called after simulation to ensure that the proposal
    is valid. This function checks the proposal's state after the simulation and
    ensures that the actions built in the `build` function apply the expected
    changes.
-   `getCalldata`: function used to generate the calldata for submitting the
    proposal. It's not necessary to override this function, as it's already
    implemented in the GovernorOzProposal contract.

When running a proposal through the `forge script`, FPS calls all the functions described above in the following order: `deploy`, `build`, `simulate`, `validate`, and `getCalldata` to ensure the proposal is valid and can be submitted to the Governor. The calldata is printed to the console, and the contracts deployed in the `deploy` function can be broadcasted to the network if needed.

Integration test suites can be integrated with proposal lifecycle simulation to
ensure the protocol remains safe and functional after the proposal is executed.

## Overview

FPS streamlines the proposal creation process by eliminating the need for manual testing configuration and calldata crafting. The proposal is created in a declarative manner using Solidity. Calldata is programmatically generated and can be easily retrieved. Prior to on-chain submission, each proposal undergoes testing against the Arbitrum Integration Test Suite in a mainnet forked environment to ensure it functions as intended. CI can be used to streamline the process even more by outputting the calldata generated from a proposal onto the pull request itself, adding yet another layer of checks that the calldata was properly crafted. Additionally, this framework allows testing not only of governance proposals but also of their associated deployment scripts. After the full lifecycle simulation and testing, the proposal can be submitted to the Governor with increased confidence given the higher level of testing and lower amount of human input. Using FPS the steps 3, 4 and 5 of the current Arbitrum proposal creation process can be combined into a single step.
