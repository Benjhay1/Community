;; Decentralized Voting System
;; A secure smart contract for creating and managing proposals and votes on a blockchain

;; Define data maps and variables
(define-map proposals 
  { proposal-id: uint }
  { 
    title: (string-ascii 100),
    description: (string-ascii 500),
    creator: principal,
    creation-time: uint,
    end-time: uint,
    status: (string-ascii 20) ;; "active", "ended", "canceled"
  }
)

(define-map votes
  { proposal-id: uint, voter: principal }
  { vote: (string-ascii 10) } ;; "yes", "no", "abstain"
)

(define-map registered-voters
  { address: principal }
  { 
    registered: bool,
    registration-time: uint
  }
)

(define-map vote-counts
  { proposal-id: uint }
  {
    yes-votes: uint,
    no-votes: uint,
    abstain-votes: uint
  }
)

(define-data-var proposal-count uint u0)
(define-data-var admin principal tx-sender)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-REGISTERED (err u101))
(define-constant ERR-NOT-REGISTERED (err u102))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u103))
(define-constant ERR-ALREADY-VOTED (err u104))
(define-constant ERR-VOTING-ENDED (err u105))
(define-constant ERR-INVALID-VOTE (err u106))

;; Register as a voter
(define-public (register-voter)
  (let ((current-time (get-block-info? time u0)))
    (if (default-to false (get registered (map-get? registered-voters { address: tx-sender })))
      ERR-ALREADY-REGISTERED
      (begin
        (map-set registered-voters 
          { address: tx-sender } 
          { 
            registered: true, 
            registration-time: (default-to u0 current-time)
          }
        )
        (ok true)
      )
    )
  )
)

;; Create a new proposal
(define-public (create-proposal (title (string-ascii 100)) (description (string-ascii 500)) (duration uint))
  (let ((current-time (get-block-info? time u0))
        (new-id (+ (var-get proposal-count) u1)))
    (if (default-to false (get registered (map-get? registered-voters { address: tx-sender })))
      (begin
        (map-set proposals 
          { proposal-id: new-id }
          { 
            title: title,
            description: description,
            creator: tx-sender,
            creation-time: (default-to u0 current-time),
            end-time: (+ (default-to u0 current-time) duration),
            status: "active"
          }
        )
        (map-set vote-counts
          { proposal-id: new-id }
          {
            yes-votes: u0,
            no-votes: u0,
            abstain-votes: u0
          }
        )
        (var-set proposal-count new-id)
        (ok new-id)
      )
      ERR-NOT-REGISTERED
    )
  )
)

;; Cast a vote on a proposal
(define-public (cast-vote (proposal-id uint) (vote-value (string-ascii 10)))
  (let ((current-time (get-block-info? time u0))
        (proposal (map-get? proposals { proposal-id: proposal-id }))
        (existing-vote (map-get? votes { proposal-id: proposal-id, voter: tx-sender })))
    
    (asserts! (is-some proposal) ERR-PROPOSAL-NOT-FOUND)
    (asserts! (default-to false (get registered (map-get? registered-voters { address: tx-sender }))) ERR-NOT-REGISTERED)
    (asserts! (is-none existing-vote) ERR-ALREADY-VOTED)
    (asserts! (< (default-to u0 current-time) (get end-time (unwrap! proposal ERR-PROPOSAL-NOT-FOUND))) ERR-VOTING-ENDED)
    (asserts! (or (is-eq vote-value "yes") (is-eq vote-value "no") (is-eq vote-value "abstain")) ERR-INVALID-VOTE)
    
    (map-set votes { proposal-id: proposal-id, voter: tx-sender } { vote: vote-value })
    
    ;; Update vote counts
    (let ((counts (unwrap! (map-get? vote-counts { proposal-id: proposal-id }) ERR-PROPOSAL-NOT-FOUND)))
      (if (is-eq vote-value "yes")
        (map-set vote-counts { proposal-id: proposal-id } 
          (merge counts { yes-votes: (+ (get yes-votes counts) u1) }))
        (if (is-eq vote-value "no")
          (map-set vote-counts { proposal-id: proposal-id } 
            (merge counts { no-votes: (+ (get no-votes counts) u1) }))
          (map-set vote-counts { proposal-id: proposal-id } 
            (merge counts { abstain-votes: (+ (get abstain-votes counts) u1) }))
        )
      )
    )
    
    (ok true)
  )
)