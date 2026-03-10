
## ARCHITECTURE.md

# ARES Treasury Architecture

## Overview
This project is designed to securely manage protocol assets, allowing governance-controlled proposals while preventing attacks commonly seen in DeFi treasury protocols using  ARES Protocol, a ARES manages $500M+ in treasury assets and distributes capital to contributors, liquidity providers, and governance participants as a case study.
  

### Module Separation

##ProposalModule
   - This file Handles proposal creation, cancellation, and metadata storage and the Proposal lifecycle are listed below;
     1. Creation (using hash-based ID): this can be done by only valid governor and Ensures each proposal has a unique ID, even if someone submits the same target, value, and data multiple times. Also, each proposal has it own unique nonce which provides replay protection: if an attacker tries to submit the same transaction twice, the nonce will differ, so the id is unique. THe noncec also helps with off-chain tracking: each proposal can be referenced uniquely by id

     2. Queueing : each proposal has to queue for a particular time before execution which prevents instant execution giving the governance chance to react. This  also ensure proposal pass through commit phases.

     3. Execution
     4. Cancellation

2. ##TimelockModule
   - Enforces a fixed delay (2 days) before execution, uses a queue mapping to prevent bypass and resistant to timestamp manipulation.

3. ##RewardsModule
   - Supports Merkle tree-based claims for contributors. and this ensure double claim prevention with the use of mapping. Root updates by governors also occurs in the file.
  

4. ##Signature Libraries
   -In this file EIP712 structured signatures was Implemented. This prevents signature replay, malleability, and cross-chain replay. Also, nonce tracking per proposal ensures same signature is not used twice.

5. ##CryptoLibraries
   - In this file the Lightweight Merkle proof verification was implemented and this ensures proof-based rewards integrity. where leaf is the hash of the user's claim 
   - The merkle proof verification also Enables gas-efficient verification for thousands of recipients. This is because only the root is stored on-chain and it enable gas efficient verification of thoousands of balances on-chain.

## Core Contract: AresTreasury.sol
- This file Integrates all modules, manages governors and treasury limits, executes proposals after cryptographic verification and timelock.Non-reentrant execution and claim patterns.
- Ensures safe treasury transfers and mitigates flash-loan governance attacks.

### Security Boundaries
- In this project, Governors can propose, queue, execute, cancel, and update Merkle roots and Only valid signatures from governors allow execution.
Also, Timelock ensures no immediate execution and claimed mapping prevents double reward withdrawals. and EIP712 structured signatures was Implemented. This prevents signature replay, malleability, and cross-chain replay. Also, nonce tracking per proposal ensures same signature is not used twice.

### Trust Assumptions
- Governors are trusted for proposal approvals.
- Users cannot bypass timelock or replay proposals.
- Treasury funds are protected by treasuryLimit and cryptographic checks to prevent unathorized access.