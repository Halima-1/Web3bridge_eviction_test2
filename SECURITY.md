# ARES Protocol: Security Analysis

Here is a breakdown of the major security risks the assignment mentioned and how I fixed them in my code:

## Major Attack Surfaces & How I Stopped Them

1. Governance Takeovers (Like Flash-Loan Attacks)
   - *The Problem*: Someone could borrow a bunch of governance tokens using a flash-loan, pass a bad proposal, and steal all the money instantly.
   - My Fix: I put a mandatory 2-day waiting period (DELAY = 2 days) on everything. This means they can't do it instantly in one block. Also, I added a treasuryLimit so even if they try, they can only move a small amount of money at a time, not the whole treasury.

2.Signature Replays
   - *The Problem*: Someone takes a valid signature used for an old proposal and uses it again, or uses it on a different blockchain to steal money.
   - *My Fix*: I used EIP-712. This means every signature is tied exactly to this specific smart contract and the current chain ID. I also used a nonce that goes up by 1 every time. Once a signature is used, my code remembers it (usedDigests[digest] = true), so it can never be used again.

3. Double Claiming Rewards
   - *The Problem*: A sneaky user might try to claim their reward tokens over and over again. Or, someone might try to change the reward list to give themselves more.

   - *My Fix*: Only the governor can update the Merkle root (the master list). When a user claims their tokens, my code marks them as claimed (claimed[msg.sender] = true). If they try to claim again, the transaction will just fail.

4. Timelock Bypasses (Reentrancy)
   - *The Problem*: A hacker creates a fake contract that calls back into my treasury contract over and over before my code can update its records, skipping the waiting line.
   - *My Fix*: I added a nonReentrant lock to all the important functions. Basically, while money is moving, the function locks the door so nobody can re-enter. I also make sure to update all the records (like proposal.executed = true) *before* I actually send any money.

## Remaining Risks

1.Governors Going Bad: My system depends on the "governors" being honest. Since they are the only ones who can queue and execute proposals, if a hacker manages to steal the governor's private keys, they could technically queue a bad proposal. The 2-day delay gives the community time to react, but if nobody notices, the hacker will win eventually.
2.Bad Proposal Data: If the governors vote for a proposal that calls a broken external contract, the money will still be lost. My system safely executes the proposal, but it doesn't know if the target contract itself is safe.
