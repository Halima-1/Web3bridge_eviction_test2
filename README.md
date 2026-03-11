# ARES Protocol: Treasury System

This is my code for the ARES Protocol treasury. The assignment was to build a secure treasury system from scratch that can handle lots of money without getting hacked by things like flash-loans or bad governance takeovers. 

## How It Works

Instead of putting all the code in one big messy file, I split things up. The main contract is AresTreasury.sol, and it uses a few helpers to get the job done:

1. **Creating a Proposal (propose)**: The governors (admins) can create a proposal to move money or make a contract call. I added a rule called `treasuryLimit` so nobody can drain the whole treasury at once, even if they take over the governance.
2. **Queueing (`queue`)**: Once a proposal is made, it goes into a waiting line. This starts a timer.
3. **Execution (`execute`)**: After the timer finishes (2 days), the proposal can finally run. To do this, a governor has to provide a secure signature. I used special math (EIP-712 nonces) to make sure nobody can use the same signature twice.
4. **Cancellation (`cancel`)**: If something looks wrong while the proposal is waiting in line, a governor can cancel it before it runs.
5. **Claiming Rewards (`claim`)**: I built a way for users to claim their token rewards. To save on gas fees for thousands of users, I used a Merkle tree. Users just prove they are on the list and get their tokens.

## Code Structure

Here is how my files are organized to make it easy to read:

- `src/core/AresTreasury.sol`: The main contract that holds the money and handles the final rules.
- `src/modules/Proposal.sol`: Keeps track of the proposals and makes sure nobody reuses the same proposal ID.
- `src/modules/TimeLock.sol`: Forces the 2-day waiting period so nothing happens instantly.
- `src/modules/AresRewards.sol`: The gas-saving Merkle system for users to claim their rewards.
- `src/libraries/...`: Some extra math files to handle the signatures and Merkle proofs securely.

## Tests

I wrote a bunch of tests in Foundry in the `test/AresTreasury.t.sol` file. 
- I tested the happy paths (like making a proposal and watching it succeed).
- I also wrote 10+ negative tests to prove the system stops hackers (testing things like double-claiming, bad signatures, and trying to skip the waiting line).

To run my tests, just type:

```shell
forge test -vvvv
```
