# DecenVote: Decentralized Voting System

A secure blockchain-based smart contract written in Clarity for creating and managing decentralized voting proposals.

## Overview

This smart contract implements a complete decentralized voting system that allows:
- User registration as voters
- Creation of proposals with customizable voting periods
- Secure vote casting with "yes", "no", or "abstain" options
- Automatic vote tallying

## Key Functions

- `register-voter`: Register yourself as an eligible voter
- `create-proposal`: Create a new proposal (title, description, duration)
- `cast-vote`: Vote on an existing proposal

## Error Handling

The contract includes comprehensive error handling for common scenarios:
- Attempting to register twice
- Voting without registration
- Voting on non-existent proposals
- Voting after a proposal has ended
- Attempting to vote multiple times

## Usage Example

```clarity
;; Register as a voter
(contract-call? .decenvote register-voter)

;; Create a proposal that lasts 10000 blocks
(contract-call? .decenvote create-proposal "Community Treasury" "Should we allocate 500 tokens to community projects?" u10000)

;; Cast a vote (yes/no/abstain) on proposal #1
(contract-call? .decenvote cast-vote u1 "yes")
```

## Data Structure

The contract maintains several data maps:
- `proposals`: Stores all proposal details
- `votes`: Records individual votes
- `registered-voters`: Tracks voter registration
- `vote-counts`: Maintains running vote tallies per proposal