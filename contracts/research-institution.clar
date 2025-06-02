;; Research Institution Verification Contract
;; Manages verified research institutions for dark energy studies

(define-non-fungible-token institution-nft uint)

(define-data-var institution-counter uint u0)

(define-map institutions
  { institution-id: uint }
  {
    name: (string-ascii 100),
    principal: principal,
    verification-date: uint,
    research-focus: (string-ascii 200),
    is-active: bool
  }
)

(define-map institution-by-principal
  { owner: principal }
  { institution-id: uint }
)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INSTITUTION-EXISTS (err u101))
(define-constant ERR-INSTITUTION-NOT-FOUND (err u102))
(define-constant ERR-INVALID-INPUT (err u103))

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Register a new research institution
(define-public (register-institution (name (string-ascii 100)) (research-focus (string-ascii 200)))
  (let (
    (institution-id (+ (var-get institution-counter) u1))
    (existing-institution (map-get? institution-by-principal { owner: tx-sender }))
  )
    (asserts! (is-none existing-institution) ERR-INSTITUTION-EXISTS)
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)

    (try! (nft-mint? institution-nft institution-id tx-sender))

    (map-set institutions
      { institution-id: institution-id }
      {
        name: name,
        principal: tx-sender,
        verification-date: block-height,
        research-focus: research-focus,
        is-active: true
      }
    )

    (map-set institution-by-principal
      { owner: tx-sender }
      { institution-id: institution-id }
    )

    (var-set institution-counter institution-id)
    (ok institution-id)
  )
)

;; Verify an institution (only contract owner)
(define-public (verify-institution (institution-id uint))
  (let (
    (institution (unwrap! (map-get? institutions { institution-id: institution-id }) ERR-INSTITUTION-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)

    (map-set institutions
      { institution-id: institution-id }
      (merge institution { is-active: true })
    )
    (ok true)
  )
)

;; Get institution details
(define-read-only (get-institution (institution-id uint))
  (map-get? institutions { institution-id: institution-id })
)

;; Get institution by principal
(define-read-only (get-institution-by-principal (owner principal))
  (match (map-get? institution-by-principal { owner: owner })
    institution-ref (map-get? institutions { institution-id: (get institution-id institution-ref) })
    none
  )
)

;; Check if principal is verified institution
(define-read-only (is-verified-institution (owner principal))
  (match (get-institution-by-principal owner)
    institution (get is-active institution)
    false
  )
)
