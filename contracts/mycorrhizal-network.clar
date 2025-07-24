;; Mycorrhizal Network Enhancement Contract
;; Strengthens underground fungal networks that support forest health

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-NETWORK-EXISTS (err u501))
(define-constant ERR-NETWORK-NOT-FOUND (err u502))
(define-constant ERR-INVALID-INPUT (err u503))
(define-constant ERR-INSUFFICIENT-FUNDS (err u504))
(define-constant ERR-TREE-NOT-FOUND (err u505))

;; Data Variables
(define-data-var next-network-id uint u1)
(define-data-var next-tree-id uint u1)

;; Data Maps
(define-map mycorrhizal-networks
  uint
  {
    network-name: (string-ascii 100),
    location: {lat: int, lon: int},
    forest-area-hectares: uint,
    dominant-tree-species: (string-ascii 100),
    fungal-species-count: uint,
    network-density: uint,
    carbon-storage-capacity: uint,
    nutrient-exchange-rate: uint,
    status: (string-ascii 20),
    established-by: principal,
    establishment-date: uint
  }
)

(define-map network-trees
  uint
  {
    network-id: uint,
    tree-species: (string-ascii 100),
    age-years: uint,
    diameter-cm: uint,
    health-status: (string-ascii 20),
    mycorrhizal-connections: uint,
    carbon-contribution: uint,
    nutrient-uptake-rate: uint,
    location: {lat: int, lon: int},
    monitored-by: principal
  }
)

(define-map authorized-mycologists principal bool)
(define-map network-funding uint uint)
(define-map fungal-inoculations
  {network-id: uint, inoculation-id: uint}
  {
    fungal-species: (string-ascii 100),
    inoculation-method: (string-ascii 50),
    spore-concentration: uint,
    application-area: uint,
    success-rate: uint,
    application-date: uint,
    applied-by: principal
  }
)

(define-map carbon-measurements
  {network-id: uint, measurement-id: uint}
  {
    measurement-date: uint,
    total-carbon-stored: uint,
    carbon-sequestration-rate: uint,
    soil-carbon-content: uint,
    biomass-carbon: uint,
    measured-by: principal
  }
)

;; Authorization Functions
(define-public (authorize-mycologist (mycologist principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set authorized-mycologists mycologist true))
  )
)

(define-public (revoke-mycologist (mycologist principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-delete authorized-mycologists mycologist))
  )
)

(define-read-only (is-authorized-mycologist (mycologist principal))
  (default-to false (map-get? authorized-mycologists mycologist))
)

;; Network Management Functions
(define-public (establish-network
  (network-name (string-ascii 100))
  (location {lat: int, lon: int})
  (forest-area-hectares uint)
  (dominant-tree-species (string-ascii 100))
  (initial-fungal-count uint))
  (let
    (
      (network-id (var-get next-network-id))
    )
    (asserts! (is-authorized-mycologist tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len network-name) u0) ERR-INVALID-INPUT)
    (asserts! (> forest-area-hectares u0) ERR-INVALID-INPUT)
    (asserts! (> (len dominant-tree-species) u0) ERR-INVALID-INPUT)
    (asserts! (> initial-fungal-count u0) ERR-INVALID-INPUT)

    (map-set mycorrhizal-networks network-id
      {
        network-name: network-name,
        location: location,
        forest-area-hectares: forest-area-hectares,
        dominant-tree-species: dominant-tree-species,
        fungal-species-count: initial-fungal-count,
        network-density: u0,
        carbon-storage-capacity: u0,
        nutrient-exchange-rate: u0,
        status: "establishing",
        established-by: tx-sender,
        establishment-date: block-height
      }
    )

    (var-set next-network-id (+ network-id u1))
    (ok network-id)
  )
)

(define-public (update-network-status (network-id uint) (new-status (string-ascii 20)))
  (let
    (
      (network-data (unwrap! (map-get? mycorrhizal-networks network-id) ERR-NETWORK-NOT-FOUND))
    )
    (asserts! (is-authorized-mycologist tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len new-status) u0) ERR-INVALID-INPUT)

    (ok (map-set mycorrhizal-networks network-id
      (merge network-data {status: new-status})
    ))
  )
)

;; Tree Management Functions
(define-public (register-tree
  (network-id uint)
  (tree-species (string-ascii 100))
  (age-years uint)
  (diameter-cm uint)
  (tree-location {lat: int, lon: int}))
  (let
    (
      (tree-id (var-get next-tree-id))
    )
    (asserts! (is-authorized-mycologist tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? mycorrhizal-networks network-id)) ERR-NETWORK-NOT-FOUND)
    (asserts! (> (len tree-species) u0) ERR-INVALID-INPUT)
    (asserts! (> age-years u0) ERR-INVALID-INPUT)
    (asserts! (> diameter-cm u0) ERR-INVALID-INPUT)

    (map-set network-trees tree-id
      {
        network-id: network-id,
        tree-species: tree-species,
        age-years: age-years,
        diameter-cm: diameter-cm,
        health-status: "healthy",
        mycorrhizal-connections: u0,
        carbon-contribution: u0,
        nutrient-uptake-rate: u0,
        location: tree-location,
        monitored-by: tx-sender
      }
    )

    (var-set next-tree-id (+ tree-id u1))
    (ok tree-id)
  )
)

(define-public (update-tree-health
  (tree-id uint)
  (health-status (string-ascii 20))
  (mycorrhizal-connections uint)
  (carbon-contribution uint)
  (nutrient-uptake-rate uint))
  (let
    (
      (tree-data (unwrap! (map-get? network-trees tree-id) ERR-TREE-NOT-FOUND))
    )
    (asserts! (is-authorized-mycologist tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> (len health-status) u0) ERR-INVALID-INPUT)

    (ok (map-set network-trees tree-id
      (merge tree-data
        {
          health-status: health-status,
          mycorrhizal-connections: mycorrhizal-connections,
          carbon-contribution: carbon-contribution,
          nutrient-uptake-rate: nutrient-uptake-rate
        }
      )
    ))
  )
)

;; Fungal Inoculation Functions
(define-public (perform-fungal-inoculation
  (network-id uint)
  (inoculation-id uint)
  (fungal-species (string-ascii 100))
  (inoculation-method (string-ascii 50))
  (spore-concentration uint)
  (application-area uint))
  (begin
    (asserts! (is-authorized-mycologist tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? mycorrhizal-networks network-id)) ERR-NETWORK-NOT-FOUND)
    (asserts! (> (len fungal-species) u0) ERR-INVALID-INPUT)
    (asserts! (> spore-concentration u0) ERR-INVALID-INPUT)
    (asserts! (> application-area u0) ERR-INVALID-INPUT)

    (ok (map-set fungal-inoculations {network-id: network-id, inoculation-id: inoculation-id}
      {
        fungal-species: fungal-species,
        inoculation-method: inoculation-method,
        spore-concentration: spore-concentration,
        application-area: application-area,
        success-rate: u0,
        application-date: block-height,
        applied-by: tx-sender
      }
    ))
  )
)

(define-public (update-inoculation-success
  (network-id uint)
  (inoculation-id uint)
  (success-rate uint))
  (let
    (
      (inoculation-data (unwrap! (map-get? fungal-inoculations {network-id: network-id, inoculation-id: inoculation-id}) ERR-NETWORK-NOT-FOUND))
    )
    (asserts! (is-authorized-mycologist tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= success-rate u100) ERR-INVALID-INPUT)

    (ok (map-set fungal-inoculations {network-id: network-id, inoculation-id: inoculation-id}
      (merge inoculation-data {success-rate: success-rate})
    ))
  )
)

;; Carbon Measurement Functions
(define-public (record-carbon-measurement
  (network-id uint)
  (measurement-id uint)
  (total-carbon-stored uint)
  (sequestration-rate uint)
  (soil-carbon uint)
  (biomass-carbon uint))
  (begin
    (asserts! (is-authorized-mycologist tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? mycorrhizal-networks network-id)) ERR-NETWORK-NOT-FOUND)
    (asserts! (> total-carbon-stored u0) ERR-INVALID-INPUT)

    (map-set carbon-measurements {network-id: network-id, measurement-id: measurement-id}
      {
        measurement-date: block-height,
        total-carbon-stored: total-carbon-stored,
        carbon-sequestration-rate: sequestration-rate,
        soil-carbon-content: soil-carbon,
        biomass-carbon: biomass-carbon,
        measured-by: tx-sender
      }
    )

    ;; Update network carbon capacity
    (let
      (
        (network-data (unwrap! (map-get? mycorrhizal-networks network-id) ERR-NETWORK-NOT-FOUND))
      )
      (ok (map-set mycorrhizal-networks network-id
        (merge network-data {carbon-storage-capacity: total-carbon-stored})
      ))
    )
  )
)

;; Network Enhancement Functions
(define-public (enhance-network-density (network-id uint) (new-density uint))
  (let
    (
      (network-data (unwrap! (map-get? mycorrhizal-networks network-id) ERR-NETWORK-NOT-FOUND))
    )
    (asserts! (is-authorized-mycologist tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-density u100) ERR-INVALID-INPUT)

    (ok (map-set mycorrhizal-networks network-id
      (merge network-data {network-density: new-density})
    ))
  )
)

(define-public (update-nutrient-exchange (network-id uint) (exchange-rate uint))
  (let
    (
      (network-data (unwrap! (map-get? mycorrhizal-networks network-id) ERR-NETWORK-NOT-FOUND))
    )
    (asserts! (is-authorized-mycologist tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (> exchange-rate u0) ERR-INVALID-INPUT)

    (ok (map-set mycorrhizal-networks network-id
      (merge network-data {nutrient-exchange-rate: exchange-rate})
    ))
  )
)

;; Funding Functions
(define-public (fund-network (network-id uint))
  (begin
    (asserts! (is-some (map-get? mycorrhizal-networks network-id)) ERR-NETWORK-NOT-FOUND)
    (asserts! (> stx-liquid-supply u0) ERR-INSUFFICIENT-FUNDS)

    (let
      (
        (current-funding (default-to u0 (map-get? network-funding network-id)))
      )
      (try! (stx-transfer? u1800000 tx-sender (as-contract tx-sender)))
      (ok (map-set network-funding network-id (+ current-funding u1800000)))
    )
  )
)

;; Read-only Functions
(define-read-only (get-network (network-id uint))
  (map-get? mycorrhizal-networks network-id)
)

(define-read-only (get-tree (tree-id uint))
  (map-get? network-trees tree-id)
)

(define-read-only (get-fungal-inoculation (network-id uint) (inoculation-id uint))
  (map-get? fungal-inoculations {network-id: network-id, inoculation-id: inoculation-id})
)

(define-read-only (get-carbon-measurement (network-id uint) (measurement-id uint))
  (map-get? carbon-measurements {network-id: network-id, measurement-id: measurement-id})
)

(define-read-only (get-network-funding (network-id uint))
  (default-to u0 (map-get? network-funding network-id))
)

(define-read-only (get-total-networks)
  (- (var-get next-network-id) u1)
)

(define-read-only (get-total-trees)
  (- (var-get next-tree-id) u1)
)

(define-read-only (calculate-network-health (network-id uint))
  (let
    (
      (network-data (unwrap! (map-get? mycorrhizal-networks network-id) ERR-NETWORK-NOT-FOUND))
      (density-score (get network-density network-data))
      (fungal-diversity-score (/ (get fungal-species-count network-data) u2))
      (exchange-score (/ (get nutrient-exchange-rate network-data) u10))
    )
    (ok (+ density-score (+ fungal-diversity-score exchange-score)))
  )
)

(define-read-only (calculate-carbon-efficiency (network-id uint))
  (let
    (
      (network-data (unwrap! (map-get? mycorrhizal-networks network-id) ERR-NETWORK-NOT-FOUND))
      (storage-capacity (get carbon-storage-capacity network-data))
      (forest-area (get forest-area-hectares network-data))
    )
    (if (> forest-area u0)
      (ok (/ storage-capacity forest-area))
      ERR-INVALID-INPUT
    )
  )
)
