;; Decentralized Roommate Matching Smart Contract
;; Version: 1.0.0
;; Description: A decentralized platform for matching roommates based on preferences and mutual agreement

;; Contract Owner
(define-constant contract-owner tx-sender)

;; Error Constants
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-insufficient-payment (err u105))
(define-constant err-already-matched (err u106))
(define-constant err-match-not-found (err u107))
(define-constant err-invalid-rating (err u108))

;; Constants
(define-constant platform-fee u1000000) ;; 1 STX in microSTX
(define-constant max-preferences u10)
(define-constant min-age u18)
(define-constant max-age u100)

;; Data Variables
(define-data-var next-user-id uint u1)
(define-data-var next-match-id uint u1)
(define-data-var platform-revenue uint u0)

;; User Profile Structure
(define-map users
  { user-id: uint }
  {
    principal: principal,
    name: (string-ascii 50),
    age: uint,
    location: (string-ascii 100),
    budget-min: uint,
    budget-max: uint,
    preferences: (list 10 (string-ascii 30)),
    bio: (string-ascii 500),
    is-active: bool,
    rating: uint,
    total-ratings: uint,
    created-at: uint
  }
)

;; User Principal to ID mapping
(define-map user-principals { principal: principal } { user-id: uint })

;; Match Requests
(define-map match-requests
  { match-id: uint }
  {
    requester-id: uint,
    target-id: uint,
    message: (string-ascii 200),
    status: (string-ascii 20), ;; "pending", "accepted", "rejected", "expired"
    created-at: uint,
    expires-at: uint
  }
)

;; Active Matches
(define-map active-matches
  { match-id: uint }
  {
    user1-id: uint,
    user2-id: uint,
    created-at: uint,
    is-active: bool
  }
)

;; User Ratings
(define-map user-ratings
  { rater-id: uint, rated-id: uint }
  { rating: uint, comment: (string-ascii 200) }
)

;; Private Functions

;; Get current block height as timestamp
(define-private (get-current-time)
  block-height
)

;; Calculate expiry time (7 days from now)
(define-private (get-expiry-time)
  (+ (get-current-time) u1008) ;; Approximately 7 days in blocks
)

;; Validate age range
(define-private (is-valid-age (age uint))
  (and (>= age min-age) (<= age max-age))
)

;; Validate budget range
(define-private (is-valid-budget (min-budget uint) (max-budget uint))
  (and (> min-budget u0) (>= max-budget min-budget))
)

;; Check if user exists
(define-private (user-exists (user-id uint))
  (is-some (map-get? users { user-id: user-id }))
)

;; Get user ID from principal
(define-private (get-user-id-from-principal (user-principal principal))
  (match (map-get? user-principals { principal: user-principal })
    user-data (some (get user-id user-data))
    none
  )
)

;; Public Functions

;; Register a new user
(define-public (register-user 
    (name (string-ascii 50))
    (age uint)
    (location (string-ascii 100))
    (budget-min uint)
    (budget-max uint)
    (preferences (list 10 (string-ascii 30)))
    (bio (string-ascii 500))
  )
  (let 
    (
      (user-id (var-get next-user-id))
      (caller tx-sender)
    )
    ;; Validate inputs
    (asserts! (is-valid-age age) err-invalid-input)
    (asserts! (is-valid-budget budget-min budget-max) err-invalid-input)
    (asserts! (is-none (get-user-id-from-principal caller)) err-already-exists)
    
    ;; Create user profile
    (map-set users 
      { user-id: user-id }
      {
        principal: caller,
        name: name,
        age: age,
        location: location,
        budget-min: budget-min,
        budget-max: budget-max,
        preferences: preferences,
        bio: bio,
        is-active: true,
        rating: u0,
        total-ratings: u0,
        created-at: (get-current-time)
      }
    )
    
    ;; Map principal to user ID
    (map-set user-principals { principal: caller } { user-id: user-id })
    
    ;; Increment user ID counter
    (var-set next-user-id (+ user-id u1))
    
    (ok user-id)
  )
)

;; Update user profile
(define-public (update-profile
    (name (string-ascii 50))
    (age uint)
    (location (string-ascii 100))
    (budget-min uint)
    (budget-max uint)
    (preferences (list 10 (string-ascii 30)))
    (bio (string-ascii 500))
  )
  (let 
    (
      (caller tx-sender)
      (user-id-opt (get-user-id-from-principal caller))
    )
    (match user-id-opt
      user-id
      (let 
        (
          (user-data (unwrap! (map-get? users { user-id: user-id }) err-not-found))
        )
        ;; Validate inputs
        (asserts! (is-valid-age age) err-invalid-input)
        (asserts! (is-valid-budget budget-min budget-max) err-invalid-input)
        
        ;; Update profile
        (map-set users 
          { user-id: user-id }
          (merge user-data {
            name: name,
            age: age,
            location: location,
            budget-min: budget-min,
            budget-max: budget-max,
            preferences: preferences,
            bio: bio
          })
        )
        (ok true)
      )
      err-not-found
    )
  )
)

;; Send match request (requires platform fee)
(define-public (send-match-request (target-user-id uint) (message (string-ascii 200)))
  (let 
    (
      (caller tx-sender)
      (requester-id-opt (get-user-id-from-principal caller))
      (match-id (var-get next-match-id))
    )
    (match requester-id-opt
      requester-id
      (begin
        ;; Validate target user exists
        (asserts! (user-exists target-user-id) err-not-found)
        (asserts! (not (is-eq requester-id target-user-id)) err-invalid-input)
        
        ;; Transfer platform fee
        (try! (stx-transfer? platform-fee caller contract-owner))
        (var-set platform-revenue (+ (var-get platform-revenue) platform-fee))
        
        ;; Create match request
        (map-set match-requests
          { match-id: match-id }
          {
            requester-id: requester-id,
            target-id: target-user-id,
            message: message,
            status: "pending",
            created-at: (get-current-time),
            expires-at: (get-expiry-time)
          }
        )
        
        ;; Increment match ID
        (var-set next-match-id (+ match-id u1))
        
        (ok match-id)
      )
      err-unauthorized
    )
  )
)

;; Respond to match request
(define-public (respond-to-match-request (match-id uint) (accept bool))
  (let 
    (
      (caller tx-sender)
      (responder-id-opt (get-user-id-from-principal caller))
      (request-data (unwrap! (map-get? match-requests { match-id: match-id }) err-match-not-found))
    )
    (match responder-id-opt
      responder-id
      (begin
        ;; Validate responder is the target
        (asserts! (is-eq responder-id (get target-id request-data)) err-unauthorized)
        (asserts! (is-eq (get status request-data) "pending") err-invalid-input)
        (asserts! (< (get-current-time) (get expires-at request-data)) err-invalid-input)
        
        (if accept
          (begin
            ;; Accept the match
            (map-set match-requests
              { match-id: match-id }
              (merge request-data { status: "accepted" })
            )
            
            ;; Create active match
            (map-set active-matches
              { match-id: match-id }
              {
                user1-id: (get requester-id request-data),
                user2-id: responder-id,
                created-at: (get-current-time),
                is-active: true
              }
            )
            (ok "accepted")
          )
          (begin
            ;; Reject the match
            (map-set match-requests
              { match-id: match-id }
              (merge request-data { status: "rejected" })
            )
            (ok "rejected")
          )
        )
      )
      err-unauthorized
    )
  )
)

;; Rate a user (only after successful match)
(define-public (rate-user (rated-user-id uint) (rating uint) (comment (string-ascii 200)))
  (let 
    (
      (caller tx-sender)
      (rater-id-opt (get-user-id-from-principal caller))
    )
    (match rater-id-opt
      rater-id
      (let 
        (
          (rated-user (unwrap! (map-get? users { user-id: rated-user-id }) err-not-found))
        )
        ;; Validate rating range (1-5)
        (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
        
        ;; Add rating
        (map-set user-ratings
          { rater-id: rater-id, rated-id: rated-user-id }
          { rating: rating, comment: comment }
        )
        
        ;; Update user's average rating
        (let 
          (
            (current-total (get total-ratings rated-user))
            (current-rating (get rating rated-user))
            (new-total (+ current-total u1))
            (new-average (/ (+ (* current-rating current-total) rating) new-total))
          )
          (map-set users
            { user-id: rated-user-id }
            (merge rated-user {
              rating: new-average,
              total-ratings: new-total
            })
          )
        )
        
        (ok true)
      )
      err-unauthorized
    )
  )
)

;; Deactivate user profile
(define-public (deactivate-profile)
  (let 
    (
      (caller tx-sender)
      (user-id-opt (get-user-id-from-principal caller))
    )
    (match user-id-opt
      user-id
      (let 
        (
          (user-data (unwrap! (map-get? users { user-id: user-id }) err-not-found))
        )
        (map-set users
          { user-id: user-id }
          (merge user-data { is-active: false })
        )
        (ok true)
      )
      err-unauthorized
    )
  )
)

;; Read-only Functions

;; Get user profile
(define-read-only (get-user-profile (user-id uint))
  (map-get? users { user-id: user-id })
)

;; Get user profile by principal
(define-read-only (get-user-by-principal (user-principal principal))
  (match (get-user-id-from-principal user-principal)
    user-id (map-get? users { user-id: user-id })
    none
  )
)

;; Get match request
(define-read-only (get-match-request (match-id uint))
  (map-get? match-requests { match-id: match-id })
)

;; Get active match
(define-read-only (get-active-match (match-id uint))
  (map-get? active-matches { match-id: match-id })
)

;; Get platform statistics
(define-read-only (get-platform-stats)
  {
    total-users: (- (var-get next-user-id) u1),
    total-matches: (- (var-get next-match-id) u1),
    platform-revenue: (var-get platform-revenue)
  }
)

;; Owner-only function to withdraw platform fees
(define-public (withdraw-fees (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (<= amount (var-get platform-revenue)) err-insufficient-payment)
    (try! (stx-transfer? amount (as-contract tx-sender) contract-owner))
    (var-set platform-revenue (- (var-get platform-revenue) amount))
    (ok amount)
  )
)