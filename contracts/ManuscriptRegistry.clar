;; Manuscript Registry Smart Contract
;; This contract handles the registration of digitized ancient manuscripts,
;; storing unique hashes, metadata, and ownership information.
;; It includes features for versioning, categorization, collaboration,
;; status updates, and revenue sharing to make it robust and useful.

;; Constants
(define-constant ERR-ALREADY-REGISTERED u1)
(define-constant ERR-NOT-OWNER u2)
(define-constant ERR-INVALID-HASH u3)
(define-constant ERR-INVALID-PARAM u4)
(define-constant ERR-NOT-FOUND u5)
(define-constant ERR-INVALID-VERSION u6)
(define-constant ERR-MAX-TAGS-REACHED u7)
(define-constant ERR-NOT-COLLABORATOR u8)
(define-constant ERR-INVALID-PERCENTAGE u9)
(define-constant ERR-TOTAL-PERCENTAGE-EXCEEDS-100 u10)
(define-constant MAX-TAGS 10)
(define-constant MAX-COLLABORATORS 20)
(define-constant MAX-VERSIONS 50)

;; Data Maps
(define-map manuscript-registry
  { hash: (buff 32) }  ;; Unique SHA-256 hash of the digitized manuscript
  {
    owner: principal,
    timestamp: uint,  ;; Block height at registration
    title: (string-utf8 200),
    description: (string-utf8 1000),
    historical-context: (string-utf8 2000),
    language: (string-utf8 50),
    estimated-age: uint
  }
)

(define-map manuscript-versions
  { hash: (buff 32), version: uint }
  {
    updated-hash: (buff 32),
    update-notes: (string-utf8 500),
    timestamp: uint,
    updater: principal
  }
)

(define-map manuscript-categories
  { hash: (buff 32) }
  {
    primary-category: (string-utf8 100),
    tags: (list 10 (string-utf8 50))
  }
)

(define-map manuscript-collaborators
  { hash: (buff 32), collaborator: principal }
  {
    role: (string-utf8 100),
    permissions: (list 5 (string-utf8 50)),  ;; e.g., "edit-metadata", "add-version"
    added-at: uint
  }
)

(define-map manuscript-status
  { hash: (buff 32) }
  {
    status: (string-utf8 50),  ;; e.g., "active", "archived", "under-review"
    visibility: bool,  ;; Public or private
    last-updated: uint
  }
)

(define-map revenue-shares
  { hash: (buff 32), participant: principal }
  {
    percentage: uint,  ;; 0-100
    total-received: uint  ;; In micro-STX or other unit
  }
)

(define-map total-revenue-shares
  { hash: (buff 32) }
  uint  ;; Sum of all percentages for validation
)

;; Public Functions

(define-public (register-manuscript 
  (hash (buff 32)) 
  (title (string-utf8 200)) 
  (description (string-utf8 1000))
  (historical-context (string-utf8 2000))
  (language (string-utf8 50))
  (estimated-age uint))
  (let
    ((existing (map-get? manuscript-registry {hash: hash})))
    (if (is-some existing)
      (err ERR-ALREADY-REGISTERED)
      (if (or (is-eq (len hash) u0) (is-eq (len title) u0))
        (err ERR-INVALID-PARAM)
        (begin
          (map-set manuscript-registry
            {hash: hash}
            {
              owner: tx-sender,
              timestamp: block-height,
              title: title,
              description: description,
              historical-context: historical-context,
              language: language,
              estimated-age: estimated-age
            }
          )
          ;; Initialize status
          (map-set manuscript-status
            {hash: hash}
            {
              status: u"active",
              visibility: true,
              last-updated: block-height
            }
          )
          ;; Initialize total shares
          (map-set total-revenue-shares {hash: hash} u0)
          (ok true)
        )
      )
    )
  )
)

(define-public (transfer-ownership (hash (buff 32)) (new-owner principal))
  (let
    ((registration (map-get? manuscript-registry {hash: hash})))
    (match registration
      some-reg
      (if (is-eq (get owner some-reg) tx-sender)
        (begin
          (map-set manuscript-registry
            {hash: hash}
            (merge some-reg {owner: new-owner})
          )
          (ok true)
        )
        (err ERR-NOT-OWNER)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (add-version 
  (original-hash (buff 32)) 
  (new-hash (buff 32)) 
  (version uint) 
  (notes (string-utf8 500)))
  (let
    ((original (map-get? manuscript-registry {hash: original-hash}))
     (existing-version (map-get? manuscript-versions {hash: original-hash, version: version})))
    (match original
      some-original
      (if (is-eq (get owner some-original) tx-sender)
        (if (is-some existing-version)
          (err ERR-ALREADY-REGISTERED)
          (if (> version MAX-VERSIONS)
            (err ERR-INVALID-VERSION)
            (begin
              (map-set manuscript-versions
                {hash: original-hash, version: version}
                {
                  updated-hash: new-hash,
                  update-notes: notes,
                  timestamp: block-height,
                  updater: tx-sender
                }
              )
              (ok true)
            )
          )
        )
        (err ERR-NOT-OWNER)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (add-category 
  (hash (buff 32)) 
  (category (string-utf8 100)) 
  (tags (list 10 (string-utf8 50))))
  (let
    ((registration (map-get? manuscript-registry {hash: hash})))
    (match registration
      some-reg
      (if (is-eq (get owner some-reg) tx-sender)
        (if (> (len tags) MAX-TAGS)
          (err ERR-MAX-TAGS-REACHED)
          (begin
            (map-set manuscript-categories
              {hash: hash}
              {primary-category: category, tags: tags}
            )
            (ok true)
          )
        )
        (err ERR-NOT-OWNER)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (add-collaborator 
  (hash (buff 32)) 
  (collaborator principal) 
  (role (string-utf8 100)) 
  (permissions (list 5 (string-utf8 50))))
  (let
    ((registration (map-get? manuscript-registry {hash: hash}))
     (existing-collab (map-get? manuscript-collaborators {hash: hash, collaborator: collaborator})))
    (match registration
      some-reg
      (if (is-eq (get owner some-reg) tx-sender)
        (if (is-some existing-collab)
          (err ERR-ALREADY-REGISTERED)
          (begin
            (map-set manuscript-collaborators
              {hash: hash, collaborator: collaborator}
              {
                role: role,
                permissions: permissions,
                added-at: block-height
              }
            )
            (ok true)
          )
        )
        (err ERR-NOT-OWNER)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (update-status 
  (hash (buff 32)) 
  (new-status (string-utf8 50)) 
  (new-visibility bool))
  (let
    ((registration (map-get? manuscript-registry {hash: hash}))
     (current-status (map-get? manuscript-status {hash: hash})))
    (match registration
      some-reg
      (if (is-eq (get owner some-reg) tx-sender)
        (match current-status
          some-status
          (begin
            (map-set manuscript-status
              {hash: hash}
              {
                status: new-status,
                visibility: new-visibility,
                last-updated: block-height
              }
            )
            (ok true)
          )
          (err ERR-NOT-FOUND)
        )
        (err ERR-NOT-OWNER)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (set-revenue-share 
  (hash (buff 32)) 
  (participant principal) 
  (percentage uint))
  (let
    ((registration (map-get? manuscript-registry {hash: hash}))
     (current-total (default-to u0 (map-get? total-revenue-shares {hash: hash}))))
    (match registration
      some-reg
      (if (is-eq (get owner some-reg) tx-sender)
        (if (or (> percentage u100) (<= percentage u0))
          (err ERR-INVALID-PERCENTAGE)
          (let
            ((new-total (+ current-total percentage)))
            (if (> new-total u100)
              (err ERR-TOTAL-PERCENTAGE-EXCEEDS-100)
              (begin
                (map-set revenue-shares
                  {hash: hash, participant: participant}
                  {percentage: percentage, total-received: u0}
                )
                (map-set total-revenue-shares {hash: hash} new-total)
                (ok true)
              )
            )
          )
        )
        (err ERR-NOT-OWNER)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-public (distribute-revenue (hash (buff 32)) (amount uint))
  (let
    ((registration (map-get? manuscript-registry {hash: hash})))
    (match registration
      some-reg
      (if (is-eq (get owner some-reg) tx-sender)
        (begin
          ;; This would typically involve STX transfers, but for simulation, we update totals
          ;; In real, use (try! (stx-transfer? share tx-sender participant))
          (map-set revenue-shares
            {hash: hash, participant: tx-sender}  ;; Placeholder, in real iterate over shares
            (let ((current (default-to {percentage: u0, total-received: u0} (map-get? revenue-shares {hash: hash, participant: tx-sender}))))
              (merge current {total-received: (+ (get total-received current) amount)})
            )
          )
          (ok true)
        )
        (err ERR-NOT-OWNER)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

;; Read-Only Functions

(define-read-only (get-manuscript-details (hash (buff 32)))
  (map-get? manuscript-registry {hash: hash})
)

(define-read-only (get-version-details (hash (buff 32)) (version uint))
  (map-get? manuscript-versions {hash: hash, version: version})
)

(define-read-only (get-categories (hash (buff 32)))
  (map-get? manuscript-categories {hash: hash})
)

(define-read-only (get-collaborator (hash (buff 32)) (collaborator principal))
  (map-get? manuscript-collaborators {hash: hash, collaborator: collaborator})
)

(define-read-only (get-status (hash (buff 32)))
  (map-get? manuscript-status {hash: hash})
)

(define-read-only (get-revenue-share (hash (buff 32)) (participant principal))
  (map-get? revenue-shares {hash: hash, participant: participant})
)

(define-read-only (verify-ownership (hash (buff 32)) (claimed-owner principal))
  (let ((registration (map-get? manuscript-registry {hash: hash})))
    (match registration
      some-reg
      (if (is-eq (get owner some-reg) claimed-owner)
        (ok true)
        (err ERR-NOT-OWNER)
      )
      (err ERR-NOT-FOUND)
    )
  )
)

(define-read-only (has-permission (hash (buff 32)) (collaborator principal) (permission (string-utf8 50)))
  (let ((collab (map-get? manuscript-collaborators {hash: hash, collaborator: collaborator})))
    (match collab
      some-collab
      (ok (is-some (index-of? (get permissions some-collab) permission)))
      (err ERR-NOT-COLLABORATOR)
    )
  )
)

;; Private Functions (if needed)

(define-private (validate-hash (hash (buff 32)))
  (if (is-eq (len hash) u32)
    (ok true)
    (err ERR-INVALID-HASH)
  )
)