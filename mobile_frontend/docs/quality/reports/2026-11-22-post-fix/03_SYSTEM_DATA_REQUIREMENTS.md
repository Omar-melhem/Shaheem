# 03 — System Data Requirements (revised, post-remediation)

**Amendment 2026-11-24 (D-A82/D-A83), client implemented 2026-11-24:** §9b and the new
field rows now describe the implemented client model/UI; wire DTOs and
server contracts are still missing. Root baseline reports/hashes remain unchanged.
Earlier D-A81 status overrides still apply except where §9b extends them.

**Authority and provenance.** Revised 2026-11-22 (R10) from the final
remediation working tree on `cefad0a`. It supersedes the baseline
[`../../../03_SYSTEM_DATA_REQUIREMENTS.md`](../../../03_SYSTEM_DATA_REQUIREMENTS.md)
(kept unchanged, SHA-256 `a1f05256…`). Product authority: D-A53–D-A80 in
`../../../decisions/ARCHITECTURAL_DECISIONS.md` and
`../../../project/PRODUCT_OVERVIEW.md`. Open owner decisions are listed in
§7 and are **not** settled here.

**What this is.** Input for a database/API design discussion. It is not a
schema: no SQL, no endpoint, no retention period, no key format and no
formula is invented. `backend/` is empty and no OpenAPI exists, so every
wire name is **proposed** unless it is an existing Dart symbol.

**Scope boundary.** These are the **captain mobile app's** requirements plus
the server-side facts the approved mobile rules depend on. Admin and
Merchant portal data (merchant onboarding, service-area administration,
order creation, settlements, reports) still needs its own specification and
is listed only where a mobile field references it.

## 0. Keys

**Contract status:** `domain-only` (Dart entity/use case exists, production
adapter is a placeholder) · `approved-unimplemented` (required by an
approved decision, no code) · `proposed` (this report's suggestion) ·
`unresolved` (owner decision pending) · `local` (never leaves the device).
No field is live: there is no backend.

**Storage class:** `P` stored fact · `S` immutable snapshot · `A` aggregate /
read model (computed, not a stored fact) · `C` configuration · `E`
transport / event only · `K` secret / credential · `L` local UI state, never
persisted · `—` not stored.

**Nullability.** "Client" is the Dart type (`?` = nullable). "Business" is
whether the system must always have a value. A nullable Dart property means
the UI copes with absence; it is **not** a proposal for an optional column.
Unknown is never stored as a zero, an empty name or a default.

**Direction:** `in` server → app · `out` app → server · `server` stays on the
server · `local` device only.

## 1. Feature and operation map

| Feature | Reads | Commands | Events / invalidation | Fields |
|---|---|---|---|---|
| Sign-in and session (D-A53, D-A65) | session check, current user | sign in, refresh (approved), sign out / revoke (approved) | block → immediate revocation; one device session | AUTH-*, USER-* |
| Profile and rating (D-A77) | rating read model | — | re-read on re-show / visible resume (R03) | USER-02/03, RATE-* |
| Availability, permissions, GPS (D-A57) | availability | set availability; location report every 30 s (approved) | location older than 90 s → ineligible | AV-*, LOC-* |
| Offers (D-A45, D-A46, D-A60) | eligible offers for this captain | accept, decline | push / SignalR = re-read hint only (D-A72) | OFF-*, CMD-* |
| Active order and recovery (D-A67, D-A68, D-A73) | active order (one or none) | verify pickup PIN, start delivery, complete (approved, not built) | re-read on acceptance, startup, foreground | ORD-* |
| My Orders (D-A70) | declined offers (exists); completed deliveries (**read model missing**) | — | refresh after a confirmed decline | DECL-*, DELIV-* |
| Wallet and statistics (D-A74–D-A76) | balance + 7-day commission debits; lifetime statistics | none in the captain app (credits are Admin-side) | re-read on Wallet re-show (resume: D-P42) | WAL-*, CRED-*, LEDG-*, STAT-* |
| Legal and app identity (D-A39, D-A77) | Terms URL, Privacy URL, app version | — | — | CFG-04..06 |
| Account deletion (D-A78) | — (no status read is approved) | request deletion | completed → session ends | DEL-* |
| Push registration (D-A58, D-A72) | — | register / unregister token (approved target) | — | PUSH-* |
| Future scheduled commitments (D-A47, D-A61, D-P25) | **read model missing** | Admin assigns outside the app | — | gap (§7) |

## 2. Field dictionary — Table A: identity, meaning, type

Every ID appears exactly once here and once in Table B (§3).

| ID | Meaning | Dart symbol / proposed name | Dir. | Type and unit | Client | Business |
|---|---|---|---|---|---|---|
| DATA-AUTH-01 | Username as typed | `SignIn.call(username:)` | out | String; trimmed edges; 4–30 `[A-Za-z0-9_.]` or a 10-digit phone (D-A65) | required | required |
| DATA-AUTH-02 | Password as typed | `SignIn.call(password:)` | out | String, 8–128 (count unit runes vs UTF-16 open, §7) | required | required |
| DATA-AUTH-03 | Access token | proposed `accessToken` | in | JWT string, 15 min (D-A53) | — | required per session |
| DATA-AUTH-04 | Refresh token | proposed `refreshToken` | in | opaque string, rotated, 90 days idle (D-A53) | — | required per session |
| DATA-AUTH-05 | Device session identity | proposed `deviceSessionId` | in | opaque id | — | required (one active per captain) |
| DATA-AUTH-06 | Sign-in outcome | `SignInResult` subtypes | in | enum: success, invalid credentials, blocked, no internet, service unavailable, profile failure, not configured, failure | — | — |
| DATA-AUTH-07 | Session-check outcome | `AuthCheckResult` subtypes | in | enum: authenticated, unauthenticated, blocked, service unavailable, failure | — | — |
| DATA-USER-01 | Captain user id | `AppUser.id` | in | non-empty opaque string | required | required |
| DATA-USER-02 | Display name | `AppUser.displayName` | in | String | nullable | unresolved (Admin completes profile, D-A65) |
| DATA-USER-03 | Phone | `AppUser.phone` | in | String, 10 local digits | nullable | unresolved (uniqueness open) |
| DATA-USER-04 | Role | `AppUser.role` | in | String (`captain`) | nullable | required in Identity |
| DATA-USER-05 | Stored username | proposed `username` | server | String, case-insensitive unique | — | required |
| DATA-USER-06 | Profile complete / eligible | proposed `profileComplete` | server | bool or derived check | — | required for offers (D-P17) |
| DATA-USER-07 | Account status | proposed `accountStatus` | server | enum active / blocked | — (client sees DATA-AUTH-06/07 typed results) | required (D-A53) |
| DATA-RATE-01 | Number of ratings | `CaptainRating.ratingsCount` | in | int ≥ 0 | required | aggregate |
| DATA-RATE-02 | Average rating | `CaptainRating.average` | in | decimal | nullable (none yet) | aggregate; scale D-P37 |
| DATA-RATE-03 | Scale maximum | `CaptainRating.scaleMax` | in | decimal | nullable (never assumed 5) | unresolved D-P37 |
| DATA-RATE-04 | One rating's value | proposed `rating.value` | server | number on DATA-RATE-03's scale | — | unresolved |
| DATA-RATE-05 | Who rated | proposed `rating.raterRef` | server | reference (merchant? customer? Admin?) | — | unresolved (actor not approved) |
| DATA-RATE-06 | When rated | proposed `rating.ratedAt` | server | UTC timestamp | — | unresolved |
| DATA-RATE-07 | Rated order | proposed `rating.orderRef` | server | → DATA-ORD-01 | — | unresolved (per order or per period) |
| DATA-AV-01 | Server-confirmed availability | `CaptainAvailability` | in | enum available / unavailable | nullable (unknown) | required |
| DATA-AV-02 | Requested availability | `ChangeCaptainAvailability.call(requested)` | out | same enum | required | — |
| DATA-AV-03 | Availability changed at | proposed `changedAt` | server | UTC timestamp | — | proposed (audit) |
| DATA-LOC-01 | Captain latitude | proposed `latitude` (report) | out | decimal degrees, −90..90 | — | required per report |
| DATA-LOC-02 | Captain longitude | proposed `longitude` (report) | out | decimal degrees, −180..180 | — | required per report |
| DATA-LOC-03 | Fix accuracy | proposed `accuracyM` | out | metres; ≤ 100 accepted (D-A57) | — | required |
| DATA-LOC-04 | Device capture time | proposed `capturedAt` | out | UTC timestamp | — | required |
| DATA-LOC-05 | Server receive time | proposed `receivedAt` | server | UTC timestamp (90 s freshness uses server clock) | — | required |
| DATA-LOC-06 | Reporting captain | proposed `captainRef` | server | → DATA-USER-01 (from the session, never a client field) | — | required |
| DATA-OFF-01 | Offer id | `CaptainOrderOffer.id` | in | opaque string | required | required |
| DATA-OFF-02 | Order reference | `CaptainOrderOffer.orderId` | in | → DATA-ORD-01 | nullable | required (navigation after acceptance, D-A73) |
| DATA-OFF-03 | Offer kind | `CaptainOrderOffer.kind` | in | enum instant / scheduled | defaults instant | required |
| DATA-OFF-04 | Merchant name | `merchantName` | in | non-empty String (server data) | required | required |
| DATA-OFF-05 | Pickup description | `pickupLabel` | in | String (area or merchant address text) | nullable | unresolved |
| DATA-OFF-06 | Delivery area | `deliveryAreaName` | in | String — an area, never a point | required | required |
| DATA-OFF-07 | Full delivery fee | `deliveryFeeFils` | in | int fils ≥ 0 (500-fils steps per area tariff) | required | required |
| DATA-OFF-08 | Scheduled pickup time | `scheduledPickupAt` | in | timestamp; shown in local time (zone semantics open) | nullable | required when kind = scheduled |
| DATA-OFF-09 | Commission amount snapshot | `OfferCommissionSnapshot.amountFils` | in | int fils, ≤ DATA-OFF-07 | nullable | required (accept is blocked without it) |
| DATA-OFF-10 | Commission rate snapshot | `OfferCommissionSnapshot.rateBasisPoints` | in | int basis points 0–10000 | nullable | required |
| DATA-OFF-11 | Offer expiry | proposed `expiresAt` | server (maybe in) | UTC timestamp (60 s per round; 2 min private, D-A60) | — (client needs no countdown today) | required, server-enforced |
| DATA-OFF-12 | Dispatch round | proposed `dispatchRound` | server | int 1..3 (5 km / 10 km / city, D-A60/D-P33) | — | required |
| DATA-OFF-13 | Private vs public mode | proposed `isPrivate` | server | bool | — | required |
| DATA-OFF-14 | Target captain | proposed `captainRef` | server | → DATA-USER-01 | — | required (each offer targets one captain) |
| DATA-OFF-15 | Offer state | proposed `offerStatus` | server | enum open / accepted / declined / expired / withdrawn (proposed set) | — | required |
| DATA-CMD-01 | Accept input | `acceptOffer(offerId)` | out | → DATA-OFF-01 | required | — |
| DATA-CMD-02 | Decline input | `declineOffer(offerId)` | out | → DATA-OFF-01 | required | — |
| DATA-CMD-03 | Command outcome | `OfferCommandResult` subtypes | in | enum confirmed / no longer available / refused / not configured / unconfirmed | — | — |
| DATA-CMD-04 | Request key | proposed `Idempotency-Key` header | out | opaque, one per attempted operation (D-A56) | — | required; **owner of the key and its retry lifetime: API contract (§7)** |
| DATA-DECL-01 | Declined offer | `DeclinedOfferRecord.offerId` | in | → DATA-OFF-01 | required | required |
| DATA-DECL-02 | Declined at | `declinedAt` | in | UTC timestamp | nullable | required |
| DATA-DECL-03 | Merchant name | `merchantName` | in | String | nullable | unresolved |
| DATA-DECL-04 | Offer kind | `kind` | in | enum | nullable | unresolved |
| DATA-DECL-05 | Order reference | proposed `orderRef` | in | → DATA-ORD-01 | — | proposed, **not required by the current screen** |
| DATA-DECL-06 | Delivery area | proposed `deliveryAreaName` | in | String | — | proposed, not required by the current screen |
| DATA-DECL-07 | Deciding captain | proposed `captainRef` | server | → DATA-USER-01 | — | required |
| DATA-ORD-01 | Order id | `ActiveOrder.orderId` | in | opaque string | required | required |
| DATA-ORD-02 | Merchant (restaurant) name | `ActiveOrder.restaurantName` | in | String | required | required |
| DATA-ORD-03 | Pickup latitude | `ActiveOrder.pickupLocation.latitude` | in | decimal degrees; (0,0) invalid; inside the Admin geofence (D-A62) | nullable (map disabled) | required at order creation |
| DATA-ORD-04 | Pickup longitude | `ActiveOrder.pickupLocation.longitude` | in | same | nullable | required |
| DATA-ORD-05 | Pickup instructions | `ActiveOrder.pickupInstructions` | in | String | nullable | optional |
| DATA-ORD-06 | Active status | proposed `status` | in | enum accepted / heading_to_pickup / picked_up / on_the_way (D-A68) | — | required |
| DATA-ORD-07 | Full order status | proposed `status` (server set) | server | the 10 states of `PRODUCT_OVERVIEW` §3.1 | — | required |
| DATA-ORD-08 | Delivery area | proposed `deliveryAreaName` | in | String | — | required |
| DATA-ORD-09 | Full delivery fee | proposed `deliveryFeeFils` | in | int fils | — | required |
| DATA-ORD-10 | Commission amount snapshot | proposed `commissionAmountFils` | server (maybe in) | int fils, immutable after acceptance | — | required (completion debit) |
| DATA-ORD-11 | Commission rate snapshot | proposed `commissionRateBasisPoints` | server | int basis points, immutable | — | required |
| DATA-ORD-12 | Customer phone | proposed `customerPhone` | in (to the assigned captain only) | String, 10 digits | — | approved need (captain calls before Start Delivery); access rule and retention open |
| DATA-ORD-13 | Pickup PIN | proposed `pickupPin` | server (merchant sees it; captain submits a guess) | 4 digits, single use, regenerated on reassignment (D-A67) | — (never returned to the captain) | required |
| DATA-ORD-14 | PIN failed attempts | proposed `pinFailedAttempts` | server | int 0..3, then Admin | — | required |
| DATA-ORD-15 | PIN used at | proposed `pinUsedAt` | server | UTC timestamp | — | required once picked up |
| DATA-ORD-16 | Assigned captain | proposed `assignedCaptainRef` | server | → DATA-USER-01 | — | required while assigned |
| DATA-ORD-17 | Merchant reference | proposed `merchantRef` | server | → Merchant (portal spec) | — | required |
| DATA-ORD-18 | Service area reference | proposed `deliveryAreaRef` | server | → Service area (portal spec) | — | required |
| DATA-ORD-19 | Status changed at | proposed `statusChangedAt` | in/server | UTC timestamp | — | proposed (staleness check) |
| DATA-ORD-20 | Order version | proposed `version` | in/server | int, monotonically increasing | — | proposed (not approved) |
| DATA-DELIV-01 | Completed order | proposed `orderRef` | in | → DATA-ORD-01 | — | **read model missing** |
| DATA-DELIV-02 | Completed at | proposed `deliveredAt` | in | UTC timestamp | — | missing |
| DATA-DELIV-03 | Merchant name | proposed `merchantName` | in | String | — | missing |
| DATA-DELIV-04 | Delivery area | proposed `deliveryAreaName` | in | String | — | missing |
| DATA-DELIV-05 | Delivery fee | proposed `deliveryFeeFils` | in | int fils | — | missing (display not approved) |
| DATA-WAL-01 | Single balance | `WalletSummary.balanceFils` | in | int fils; may be negative or above 5,000 (legacy) | required | required |
| DATA-WAL-02 | Debit entry id | `WalletCommissionDebit.id` | in | opaque string | required | required |
| DATA-WAL-03 | Debited at | `debitedAt` | in | UTC timestamp | required | required |
| DATA-WAL-04 | Commission debited | `commissionFils` | in | int fils > 0 (= DATA-ORD-10) | required | required |
| DATA-WAL-05 | Merchant name | `merchantName` | in | String | nullable | unresolved (denormalized display) |
| DATA-WAL-06 | Delivery area | `deliveryAreaName` | in | String | nullable | unresolved |
| DATA-WAL-07 | Order reference | `orderId` | in | → DATA-ORD-01 | nullable | required in the ledger |
| DATA-WAL-08 | History window start | `getWallet(historySinceUtc:)` | out | UTC timestamp = now − 7 days, inclusive | required | — (display window only) |
| DATA-CRED-01 | Credit entry id | proposed `creditId` | server | opaque string | — | required |
| DATA-CRED-02 | Credit amount | proposed `amountFils` | server | int fils > 0 | — | required |
| DATA-CRED-03 | Credited at | proposed `creditedAt` | server | UTC timestamp | — | required |
| DATA-CRED-04 | Verifying Admin | proposed `verifiedByRef` | server | → Admin identity | — | required (credit only after Admin confirmation) |
| DATA-CRED-05 | Resulting balance | proposed `balanceAfterFils` | server | int fils ≤ 5,000 at write time | — | proposed (audit of the ceiling) |
| DATA-CRED-06 | External transfer reference | proposed `transferRef` | server | String | — | unresolved (no approved field) |
| DATA-LEDG-01 | Entry type | proposed `entryType` | server | enum commission_debit / credit / adjustment | — | required |
| DATA-LEDG-02 | Financial effect key | proposed `effectKey` | server | unique per (order, effect type) | — | required (D-A56, D-A74) |
| DATA-LEDG-03 | Wallet reference | proposed `walletRef` | server | → captain wallet | — | required |
| DATA-STAT-01 | Lifetime delivered count | `CaptainDeliveryStatistics.deliveredCount` | in | int ≥ 0, all completed deliveries since start (not the 7-day window) | required | aggregate |
| DATA-STAT-02 | Lifetime earnings | `CaptainDeliveryStatistics.earningsFils` | in | int fils, lifetime | nullable («غير متوفر») | unresolved formula D-P36 |
| DATA-CFG-01 | Balance ceiling | proposed `walletBalanceCeilingFils` | server | int fils = 5,000 (D-A75) | — | required |
| DATA-CFG-02 | Global commission rate | proposed `commissionRateBasisPoints` | server | int basis points, default 2,000 (D-A59) | — | required |
| DATA-CFG-03 | Config effective from | proposed `effectiveFrom` | server | UTC timestamp | — | proposed (rate history) |
| DATA-CFG-04 | Terms URL | `LegalLinks.termsAndConditions` | local constant | HTTPS URL; empty today | — | required for release (D-P40) |
| DATA-CFG-05 | Privacy Policy URL | not present | local / config | HTTPS URL | — | required for stores (D-P40) |
| DATA-CFG-06 | App version | not present (About shows "unavailable") | local (platform) | build name + number | — | needs an approved source |
| DATA-DEL-01 | Deletion request (command) | `requestAccountDeletion()` | out | no body today | — | required |
| DATA-DEL-02 | Deletion outcome | `AccountDeletionResult` | in | enum pending / completed / not configured / no internet / reauth required / failure / **unconfirmed** (timeout, R04) | — | — |
| DATA-DEL-03 | Deletion request id | proposed `deletionRequestId` | server | opaque | — | unresolved D-P39 |
| DATA-DEL-04 | Requested at | proposed `requestedAt` | server | UTC timestamp | — | unresolved |
| DATA-DEL-05 | Completed at | proposed `completedAt` | server | UTC timestamp; null until completed | — | conditional: required iff status = completed |
| DATA-DEL-06 | Request status | proposed `status` | server | enum pending / completed (+ rejected? open) | — | unresolved |
| DATA-PUSH-01 | Push token | proposed `pushToken` | out | opaque FCM/APNs token | — | approved target, contract missing |
| DATA-PUSH-02 | Platform | proposed `platform` | out | enum android / ios | — | same |
| DATA-PUSH-03 | Device session | proposed `deviceSessionRef` | server | → DATA-AUTH-05 | — | only if the contract ties tokens to sessions |
| DATA-ORD-22 | Optional customer name | `customerName` | in | nullable String; blank omitted | domain-only (2026-11-24) | optional (D-A83) |
| DATA-ORD-23 | Optional delivery notes | `deliveryNotes` | in | nullable String; distinct from pickup instructions | domain-only (2026-11-24) | optional (D-A83) |
| DATA-DELIV-07 | Historical customer name | `customerName` | in | nullable String from the order record | domain-only (2026-11-24) | optional (D-A83) |
| DATA-DELIV-08 | Historical customer phone | `customerPhone` | in | nullable String from the order record | domain-only (2026-11-24) | optional (D-A83) |
| DATA-DELIV-09 | Historical delivery notes | `deliveryNotes` | in | nullable String from the order record | domain-only (2026-11-24) | optional (D-A83) |
| DATA-ORD-21 | Assignment reference | `ActiveOrder.assignmentRef`, `OrderCommandTarget.assignmentRef` | in → out | opaque string | nullable (until the contract defines it) | required for stale-command protection (D-A81) |
| DATA-CMD-05 | Pickup proof: entered PIN | `PickupPinProof.digits` | out | exactly 4 ASCII digits after Arabic-digit normalization, leading zeros kept | required to send | required; **never returned, stored or logged** |
| DATA-CMD-06 | PIN attempts remaining | `PickupCodeIncorrectException.remainingAttempts` | in | int 0..2 | nullable (shown only when supplied) | server-counted (3, D-A67) |
| DATA-CMD-07 | Start Delivery input | `startDelivery(OrderCommandTarget)` | out | → DATA-ORD-01 + DATA-ORD-21 | required | — |
| DATA-CMD-08 | Complete Delivery input | `completeDelivery(OrderCommandTarget)` | out | → DATA-ORD-01 + DATA-ORD-21 | required | — |
| DATA-CMD-09 | Completion receipt reference | `DeliveryCompletionReceipt.receiptRef` | in | opaque string | nullable | proposed (stable result for retries) |
| DATA-CMD-10 | Authoritative delivered-at | `DeliveryCompletionReceipt.deliveredAt` | in | UTC timestamp | nullable in the receipt | required on the order (= DATA-DELIV-02) |
| DATA-CMD-11 | Workflow command outcome | `OrderCommandResult` subtypes | in | succeeded / rejected (incorrect PIN, locked, state conflict) / not configured / no internet / unconfirmed | — | — |
| DATA-CMD-12 | Order outcome lookup | `OrderOutcome` subtypes | in | active / delivered (+ receipt) / cancelled / reassigned / unresolved | — | required to reconcile an unconfirmed completion |
| DATA-ROUTE-01 | Route polyline | `PickupRoute.path` | in | ordered list of points (captain → merchant) | — | from Google Routes DRIVE only; access design open |
| DATA-ROUTE-02 | Route distance | `PickupRoute.distanceMeters` | in | int metres | — | same |
| DATA-ROUTE-03 | Route duration | `PickupRoute.durationSeconds` | in | int seconds (no live traffic) | — | same |
| DATA-DELIV-06 | Next-page cursor | `CompletedDeliveriesPage.nextCursor` | in | opaque string | nullable (no more pages) | contract decides paging |
| DATA-LOCAL-01 | Selected tab | go_router branch index | local | int 0..3 | — | not persisted |
| DATA-LOCAL-02 | Sheet / dialog visibility | route stack (`NewOfferSheetHost`, popups) | local | — | — | not persisted |
| DATA-LOCAL-03 | Login field text | `LoginForm` controllers | local | String (password never stored) | — | not persisted |
| DATA-LOCAL-04 | Password visibility | `AppTextFormField` state | local | bool | — | not persisted |
| DATA-LOCAL-05 | Command in flight per offer | `PendingOffersState.pending` | local | offer id + action | — | not persisted |
| DATA-LOCAL-06 | Per-offer notices | `PendingOffersState.notices` | local | enum per offer id | — | not persisted |
| DATA-LOCAL-07 | Device requirement statuses | `AvailabilityPrerequisites` (location service, precise, background, notifications) | local (OS) | enum per requirement | — | not persisted |
| DATA-LOCAL-08 | Connectivity status | `AppConnectivityState` | local | enum | — | not persisted |
| DATA-LOCAL-09 | Debug preview switch | `DebugShellPreview` | local (debug builds only) | bool | — | not persisted |
| DATA-LOCAL-10 | Load bookkeeping | Cubit generations, in-flight flags, session owner tag | local | ints / flags | — | not persisted |

## 3. Field dictionary — Table B: rules, authority, storage, access

| ID | Validation / default | Source of truth | Consumers (screen → widget / owner) | Storage | Contract status | Database implication | Access | Privacy / lifecycle |
|---|---|---|---|---|---|---|---|---|
| DATA-AUTH-01 | Arabic digits normalized; edges trimmed | Captain → Identity | Login → `LoginCubit` | — | domain-only | matched against DATA-USER-05 | captain | identifying; never logged with the password |
| DATA-AUTH-02 | Not trimmed; never in state longer than the request | Captain | Login → `LoginCubit` | K (hash only, server) | domain-only | password hash in Identity | captain | secret |
| DATA-AUTH-03 | — | Server | future HTTP client | — (memory only, D-P03) | approved-unimplemented | none | system | secret |
| DATA-AUTH-04 | Rotation; reuse detection | Server | future secure storage | K (`flutter_secure_storage`, D-P03) | approved-unimplemented | hashed token per device session | system | secret; revoked on block / deletion |
| DATA-AUTH-05 | One active per captain | Server | — | P | approved-unimplemented | unique active session per captain | system | device identifier |
| DATA-AUTH-06 | Generic wording for wrong credentials | Server | Login → `login_failure_message.dart` | E | domain-only | — | — | — |
| DATA-AUTH-07 | Failure never collapses to "unauthenticated" | Server | Splash → `SplashCubit` | E | domain-only | — | — | — |
| DATA-USER-01 | Non-empty (`app_user_model.dart`) | Server | session, every request | P | domain-only | primary key of the captain identity | — | identifier |
| DATA-USER-02 | Blank → «الاسم غير متوفر» / «مرحباً بك» | Admin | Home greeting; Profile identity card | P | domain-only | captain profile column | Admin edits (D-A65) | personal |
| DATA-USER-03 | LTR-isolated on screen | Admin | Profile identity card | P | domain-only | captain profile column; uniqueness open | Admin | personal, sensitive |
| DATA-USER-04 | — | Identity | not used for routing | P | domain-only | Identity role tables | — | — |
| DATA-USER-05 | 4–30 chars, case-insensitive unique | Admin | — | P | approved-unimplemented | unique normalized username | Admin | identifying |
| DATA-USER-06 | Incomplete → no offers | Admin / server rule | — | P or derived | approved-unimplemented | column or computed check | Admin | — |
| DATA-USER-07 | Block revokes sessions at once | Admin | Splash/Login see typed results only | P | approved-unimplemented | status + audit event | Admin | — |
| DATA-RATE-01 | No five-star default; "no ratings" is its own state | Server aggregate | Profile rating card | A | domain-only | view/aggregate over DATA-RATE-04 | captain reads own | — |
| DATA-RATE-02 | Rounded to one decimal for display | Server aggregate | Profile rating card | A | unresolved D-P37 | aggregate | captain | — |
| DATA-RATE-03 | Never assumed | Config or aggregate | Profile rating card | A or C | unresolved D-P37 | config or per-rating scale | — | — |
| DATA-RATE-04 | On the scale (D-P37) | Rater | — | P | unresolved | rating fact | unresolved | — |
| DATA-RATE-05 | — | Server | — | P | unresolved | reference to the rater | unresolved | personal if a customer |
| DATA-RATE-06 | — | Server clock | — | P | unresolved | timestamp | — | — |
| DATA-RATE-07 | — | Server | — | P | unresolved | reference to the order | — | — |
| DATA-AV-01 | Change only via the requirements check + confirmed command | Server | Home availability bar → `HomeAvailabilityCubit` | P | domain-only | one current row per captain | captain requests, server decides | — |
| DATA-AV-02 | Requirements satisfied first | Captain | `HomeAvailabilityCubit` | E | domain-only | — | captain | — |
| DATA-AV-03 | — | Server clock | — | P | proposed | timestamp (+ optional history) | Admin | — |
| DATA-LOC-01 | Range check | Device | not yet sent (map uses a local read) | P (latest) + E | approved-unimplemented | latest location per captain | captain writes; Admin reads latest | highly sensitive; retention open |
| DATA-LOC-02 | Range check | Device | same | P + E | approved-unimplemented | same | same | same |
| DATA-LOC-03 | ≤ 100 m accepted | Device | — | P | approved-unimplemented | same row | — | — |
| DATA-LOC-04 | Not after receive time + skew | Device | — | P | approved-unimplemented | same row | — | — |
| DATA-LOC-05 | Freshness 90 s on server clock | Server | eligibility | P | approved-unimplemented | same row; drives eligibility queries | system | — |
| DATA-LOC-06 | From the session only | Server | — | P | approved-unimplemented | FK to captain | system | — |
| DATA-OFF-01 | Non-empty | Server | Home offer list; new-offer sheet | P | domain-only | offer primary key | target captain only | — |
| DATA-OFF-02 | Must match the active order before navigation | Server | `NewOfferSheetHost` | P | domain-only | FK to order | target captain | — |
| DATA-OFF-03 | Scheduled: accept off (D-A47, D-P35) | Server | offer card, sheet | P | domain-only | column on order/offer | — | — |
| DATA-OFF-04 | Non-empty (card asserts) | Merchant data | offer card, sheet | S (display copy) | domain-only | from merchant at dispatch | target captain | business data |
| DATA-OFF-05 | Unavailable text when absent | Merchant data | offer card, sheet | S | unresolved | from merchant | — | — |
| DATA-OFF-06 | Area, never coordinates | Service area | offer card, sheet | S | domain-only | FK to service area | — | no customer address |
| DATA-OFF-07 | ≥ 0; full fee shown, never net | Area tariff | offer card, sheet | S | domain-only | on order | — | financial |
| DATA-OFF-08 | Required for scheduled | Merchant / Admin | sheet | P | domain-only | on order | — | — |
| DATA-OFF-09 | 0 ≤ amount ≤ fee | Server snapshot | accept blocker (`order_offer.dart`) | S | domain-only | immutable on order (same as DATA-ORD-10) | — | financial |
| DATA-OFF-10 | 0–10000 | Server snapshot | same | S | domain-only | immutable on order (same as DATA-ORD-11) | — | — |
| DATA-OFF-11 | Enforced on accept | Server | none today | P | approved-unimplemented | `expires_at` + index for open offers | system | — |
| DATA-OFF-12 | 1..3 | Server | none | P | approved-unimplemented | column | system | — |
| DATA-OFF-13 | — | Server | none | P | approved-unimplemented | column | system | — |
| DATA-OFF-14 | — | Server | none (implicit in "my offers") | P | approved-unimplemented | FK; index (captain, state, expiry) | system | — |
| DATA-OFF-15 | Transitions server-side | Server | none (list contains only actionable offers) | P | proposed | column | system | — |
| DATA-CMD-01 | One command at a time per offer; first atomic accept wins | Server | `PendingOffersCubit.accept` | E | domain-only | atomic assignment of the order | captain | audited |
| DATA-CMD-02 | — | Server | `PendingOffersCubit.decline` | E | domain-only | writes DATA-DECL-* | captain | audited |
| DATA-CMD-03 | Timeout = unconfirmed (R04) | Server | offer card / sheet notices | E | domain-only | — | — | — |
| DATA-CMD-04 | Same key on retry of the same attempt | API contract | future adapter | P (server, for dedupe) | approved-unimplemented | unique (actor, operation, key) with stored result | system | retention open |
| DATA-DECL-01 | Newest first (`get_declined_offers.dart`) | Server | My Orders → declined tile | P | domain-only | decision fact (offer, captain) | captain reads own | — |
| DATA-DECL-02 | — | Server clock | declined tile | P | domain-only | timestamp | — | — |
| DATA-DECL-03 | Fallback text | Server copy | declined tile | S | unresolved | denormalized or joined | — | — |
| DATA-DECL-04 | — | Server copy | declined tile | S | unresolved | from offer | — | — |
| DATA-DECL-05 | — | Server | none | S | proposed | FK to order | — | — |
| DATA-DECL-06 | — | Server | none | S | proposed | from offer | — | — |
| DATA-DECL-07 | From the session | Server | — | P | approved-unimplemented | FK to captain | — | — |
| DATA-ORD-01 | Non-empty | Server | Home active-order card; Current Order | P | domain-only | order primary key | assigned captain only | — |
| DATA-ORD-02 | — | Merchant | same | S | domain-only | from merchant | assigned captain | business |
| DATA-ORD-03 | Invalid → map disabled, order still shown | Merchant / Admin geofence | Current Order pickup view | P | domain-only | merchant pickup point | assigned captain | business location |
| DATA-ORD-04 | same | same | same | P | domain-only | same | same | same |
| DATA-ORD-05 | — | Merchant | Current Order | P | domain-only | column | assigned captain | — |
| DATA-ORD-06 | Transitions validated by POST commands | Server | none today | P | approved-unimplemented | status enum | assigned captain reads | audited |
| DATA-ORD-07 | — | Server | — | P | approved-unimplemented | status enum + event history | Admin / system | audited |
| DATA-ORD-08 | — | Service area | none today | S | approved-unimplemented | FK to area | — | — |
| DATA-ORD-09 | — | Area tariff | none today | S | approved-unimplemented | column | — | financial |
| DATA-ORD-10 | Immutable after acceptance | Server | completion debit | S | approved-unimplemented | column | system | financial |
| DATA-ORD-11 | Immutable | Server | — | S | approved-unimplemented | column | system | — |
| DATA-ORD-12 | Never in push payloads | Merchant | future Current Order | P | approved-unimplemented | column | assigned captain while active only | sensitive; retention open |
| DATA-ORD-13 | 4 digits, one use, new on reassignment | Server | merchant portal | K | approved-unimplemented | hashed PIN + used flag | merchant sees; captain submits | secret |
| DATA-ORD-14 | ≤ 3 then Admin | Server | — | P | approved-unimplemented | counter | system | — |
| DATA-ORD-15 | — | Server clock | — | P | approved-unimplemented | timestamp | system | — |
| DATA-ORD-16 | One active delivery per captain (D-A44) | Server | — | P | approved-unimplemented | assignment fact (from / to / reason) | system | audited |
| DATA-ORD-17 | — | Merchant portal | — | P | approved-unimplemented | FK (portal spec) | — | — |
| DATA-ORD-18 | — | Admin | — | P | approved-unimplemented | FK (portal spec) | — | — |
| DATA-ORD-19 | — | Server clock | none | P | proposed | timestamp | — | — |
| DATA-ORD-20 | — | Server | none | P | proposed | version column | — | — |
| DATA-DELIV-01 | Lifetime list; paging/sort unspecified | Server | My Orders (not built) | A (read model over orders) | approved-unimplemented, contract missing | query over delivered orders by captain | captain reads own | — |
| DATA-DELIV-02 | — | Server | same | A | missing | — | — | — |
| DATA-DELIV-03 | — | Server copy | same | A | missing | — | — | — |
| DATA-DELIV-04 | — | Server copy | same | A | missing | — | — | — |
| DATA-DELIV-05 | — | Server | same | A | missing, display unapproved | — | — | financial |
| DATA-WAL-01 | Shown as returned, never clamped or derived | Server ledger | Home chip and Wallet balance card (one shell `WalletCubit`, R02) | A from the ledger, or P kept consistent atomically | domain-only | wallet balance updated in the same transaction as each ledger entry | captain reads own | financial |
| DATA-WAL-02 | — | Server ledger | Wallet debit card | P (immutable) | domain-only | ledger entry id | captain reads own | financial; never deleted (D-A74) |
| DATA-WAL-03 | Window applied only by `GetWallet` | Server | debit card | P | domain-only | index (wallet, created) | — | — |
| DATA-WAL-04 | > 0 | Server | debit card | P | domain-only | amount | — | financial |
| DATA-WAL-05 | Fallback text | Server copy | debit card | S | unresolved | join or snapshot | — | — |
| DATA-WAL-06 | Fallback text | Server copy | debit card | S | unresolved | join or snapshot | — | — |
| DATA-WAL-07 | — | Server | not displayed | P | domain-only (nullable in Dart) | FK to order | — | — |
| DATA-WAL-08 | now − 7 days, inclusive | Client | `GetWallet` | — | domain-only | range query parameter | — | — |
| DATA-CRED-01 | — | Server | not shown to the captain (D-A76) | P (immutable) | approved-unimplemented | ledger entry id | Admin writes | financial; audited |
| DATA-CRED-02 | > 0; resulting balance ≤ ceiling, atomically | Admin | — | P | approved-unimplemented | amount | Admin | financial |
| DATA-CRED-03 | — | Server clock | — | P | approved-unimplemented | timestamp | — | — |
| DATA-CRED-04 | — | Server | — | P | approved-unimplemented | FK to Admin | — | audited |
| DATA-CRED-05 | — | Server | — | P | proposed | column | Admin | — |
| DATA-CRED-06 | — | Admin | — | P | unresolved | column | Admin | — |
| DATA-LEDG-01 | — | Server | — | P | approved-unimplemented | enum | system | — |
| DATA-LEDG-02 | Unique | Server | — | P | approved-unimplemented | unique constraint (one completion debit per order) | system | — |
| DATA-LEDG-03 | — | Server | — | P | approved-unimplemented | FK | system | — |
| DATA-STAT-01 | Completed deliveries only, lifetime | Server aggregate | Wallet metric card | A | domain-only | aggregate over delivered orders | captain reads own | — |
| DATA-STAT-02 | Never 0 as stand-in | Server aggregate | Wallet metric card | A | unresolved D-P36 | aggregate; formula open | captain | financial |
| DATA-CFG-01 | Applied to the balance after a credit only | Admin config | — | C | approved-unimplemented | versioned settings | Admin | — |
| DATA-CFG-02 | Snapshotted per order | Admin config | — | C | approved-unimplemented | versioned settings | Admin | — |
| DATA-CFG-03 | — | Admin | — | C | proposed | effective-from on settings | Admin | — |
| DATA-CFG-04 | HTTPS, opened in-app (`legal_page_launcher.dart`) | Owner | Login, Profile | C (code constant) | domain-only, empty value | none or remote config (proposed) | — | — |
| DATA-CFG-05 | HTTPS | Owner | none yet | C | missing (store blocker) | same | — | — |
| DATA-CFG-06 | — | Build | About | — | missing source (package needs approval) | none | — | — |
| DATA-DEL-01 | Explicit confirmation; one submission | Captain | Settings → `AccountDeletionCubit` | E | domain-only | creates DATA-DEL-03..06 | captain (own account) | — |
| DATA-DEL-02 | Completed → session ends; unconfirmed → no resend | Server | Settings | E | domain-only | — | — | — |
| DATA-DEL-03 | — | Server | none | P | unresolved D-P39 | request id | system / Admin | retention open |
| DATA-DEL-04 | — | Server clock | none | P | unresolved | timestamp | — | — |
| DATA-DEL-05 | Null until completed | Server clock | none | P | unresolved | nullable timestamp with a check tied to status | — | — |
| DATA-DEL-06 | — | Server | none | P | unresolved | enum | — | erasure vs anonymization open |
| DATA-PUSH-01 | — | Device | none | P | approved-unimplemented | token per device/session | system | device identifier; deleted on sign-out / deletion |
| DATA-PUSH-02 | — | Device | none | P | approved-unimplemented | column | — | — |
| DATA-PUSH-03 | — | Server | none | P | unresolved | FK if supported | — | — |
| DATA-ORD-22 | Null/blank => omit | Merchant order | delivery-details section | P/S (order fact/snapshot) | domain-only | optional order-level name; no customer account | assigned captain; own history under D-A83 | personal; retention/redaction open |
| DATA-ORD-23 | Null/blank => omit; not pickup notes | Merchant order | delivery-details section | P/S | domain-only | optional delivery note | same | may contain personal data; no logs/push |
| DATA-DELIV-07 | Null/blank => omit | Historical order record | own completed-order detail page | S/read model | domain-only | preserves supplied order name | own delivery record only | retention/redaction open |
| DATA-DELIV-08 | Null/blank => omit | Historical order record | same | S/read model | domain-only | supplied historical phone | own delivery record only | sensitive; retention/redaction open |
| DATA-DELIV-09 | Null/blank => omit; wrap long text | Historical order record | same | S/read model | domain-only | supplied historical delivery notes | own delivery record only | no logs/push |
| DATA-ORD-21 | Opaque; compared, never parsed | Server | `CurrentOrderCubit` stale-answer guard | P | domain-only | assignment id (FK of the active assignment) | assigned captain | — |
| DATA-CMD-05 | Syntax only on the phone (`Validators.pickupPin`) | Captain (from the merchant) | PIN form → `CurrentOrderCubit.confirmPickup` | — (local controller only, cleared/disposed) | domain-only | compared with the hashed DATA-ORD-13 server-side | captain submits | secret; never in state, logs or analytics |
| DATA-CMD-06 | Never computed on the phone | Server | PIN form message | E | domain-only | derived from DATA-ORD-14 | — | — |
| DATA-CMD-07 | One at a time; same key on retry after unknown outcome | Server | delivery view | E | domain-only | status transition + event | assigned captain | audited |
| DATA-CMD-08 | Confirmation popup first; one at a time; same key on retry | Server | delivery view | E | domain-only | **one transaction**: delivered + one commission debit (DATA-LEDG-02 unique) | assigned captain | audited, financial |
| DATA-CMD-09 | — | Server | `CurrentOrderDelivered` | P | proposed | stored with the idempotency record (DATA-CMD-04) | system | — |
| DATA-CMD-10 | — | Server clock | history, wallet | P | domain-only | order delivered-at column | — | — |
| DATA-CMD-11 | Timeout = unconfirmed (R04) | Server | `OrderCommandNotice` | E | domain-only | — | — | — |
| DATA-CMD-12 | Absence of an active order is never proof | Server | `checkCommandStatus` | A | domain-only (contract missing) | query over order + operation records | captain (own orders) | — |
| DATA-ROUTE-01 | ≥ 2 points, else "unavailable"; never a straight line | Google Routes | `GooglePickupMap` polyline | E (not stored) | domain-only, not configured | none | — | contains the captain position: not persisted |
| DATA-ROUTE-02 | — | Google Routes | pickup route line | E | domain-only | none | — | — |
| DATA-ROUTE-03 | — | Google Routes | pickup route line | E | domain-only | none | — | — |
| DATA-DELIV-06 | Opaque; null ends paging | Server | «عرض المزيد» | E | domain-only | cursor over (captain, delivered_at, order) index | captain | — |
| DATA-LOCAL-01 | — | go_router | shell | L | local | none | — | — |
| DATA-LOCAL-02 | — | Navigator | sheet host, popups | L | local | none | — | — |
| DATA-LOCAL-03 | — | Form | Login | L | local | none | — | password never persisted |
| DATA-LOCAL-04 | — | Widget | Login | L | local | none | — | — |
| DATA-LOCAL-05 | — | `PendingOffersCubit` | offer card, sheet | L | local | none | — | — |
| DATA-LOCAL-06 | — | `PendingOffersCubit` | offer card, sheet | L | local | none | — | — |
| DATA-LOCAL-07 | Never requested at startup | OS | Home availability notice | L | local | none (not a server field) | — | — |
| DATA-LOCAL-08 | — | Connectivity monitor | banner, No Internet | L | local | none | — | — |
| DATA-LOCAL-09 | Debug builds only | Developer | Login, guard | L | local | none | — | — |
| DATA-LOCAL-10 | — | Cubits | — | L | local | none | — | — |

## 4. Relationships and cardinality

| Relationship | Cardinality | Backed by | Status |
|---|---|---|---|
| Captain identity → captain profile | 1 : 1 | DATA-USER-01..07 | approved; profile fields partly unresolved |
| Captain → device sessions | 1 : 0..1 active (history 1 : *) | DATA-AUTH-05 | approved (one device) |
| Device session → push token | 1 : 0..1 | DATA-PUSH-01..03 | approved target; tie to session unresolved |
| Captain → current availability | 1 : 1 | DATA-AV-01, DATA-AV-03 | approved |
| Captain → latest location | 1 : 0..1 (history 1 : * optional) | DATA-LOC-01..06 | approved latest; history retention open |
| Merchant → orders | 1 : * | DATA-ORD-17 | **merchant entity belongs to the portal spec** |
| Service area → orders | 1 : * | DATA-ORD-18, DATA-OFF-06 | **service-area entity belongs to the portal spec** |
| Order → offers | 1 : * (one per round × captain) | DATA-OFF-02, DATA-OFF-12, DATA-OFF-14 | approved dispatch; exact offer identity open |
| Captain → offers | 1 : * | DATA-OFF-14 | approved |
| Offer → decline decision | 1 : 0..1 | DATA-DECL-01, DATA-DECL-07 | domain-only |
| Order → assignments | 1 : * (exactly one active) | DATA-ORD-16 | approved (reassignment D-A67) |
| Captain → active delivery | 1 : 0..1 | DATA-ORD-16 + DATA-ORD-06 | approved (D-A44) |
| Order → pickup PIN | 1 : 1 per assignment | DATA-ORD-13..15 | approved |
| Captain → wallet | 1 : 1 | DATA-LEDG-03 | approved |
| Wallet → ledger entries | 1 : * | DATA-WAL-02, DATA-CRED-01, DATA-LEDG-01 | approved; immutable |
| Order → completion debit | 1 : 0..1 | DATA-LEDG-02, DATA-WAL-07 | approved (one debit, on completion only) |
| Order → rating | unresolved (0..1 or 0..*) | DATA-RATE-04..07 | unresolved D-P37 |
| Captain → deletion requests | 1 : * (at most one open: proposed) | DATA-DEL-03..06 | unresolved D-P39 |
| Captain → future scheduled commitments | 1 : * | **no field yet** | read model missing D-P25 |

## 5. Commands, invariants and consistency

| Workflow | Actor | Inputs | Server checks | State change | Money | Concurrency / idempotency | Status |
|---|---|---|---|---|---|---|---|
| Sign in | captain | DATA-AUTH-01/02 | active, profile complete for offers | new session; older one revoked | — | one device session | domain-only |
| Change availability | captain | DATA-AV-02 | permissions, eligibility, location freshness | DATA-AV-01 | — | request key (proposed) | domain-only |
| Report location | device | DATA-LOC-01..04 | accuracy ≤ 100 m | latest location | — | last `capturedAt` wins (proposed) | approved-unimplemented |
| Accept instant offer | captain | DATA-CMD-01 (+ CMD-04) | offer open and not expired; no active delivery; any wallet condition = D-P41 | assignment; status accepted; other offers withdrawn | **none** (no hold, D-A74) | first atomic accept wins; unique active assignment | domain-only |
| Decline offer | captain | DATA-CMD-02 (+ CMD-04) | offer targets the captain | decision row | none | request key | domain-only |
| Verify pickup PIN | captain | PIN guess (proposed) | status heading_to_pickup; attempts < 3 | picked_up | none | — | approved-unimplemented |
| Start delivery | captain | DATA-ORD-01 | status picked_up | on_the_way | none | request key | approved-unimplemented |
| Complete delivery | assigned captain | DATA-ORD-01 (+ key) | current assignee only | delivered | **one** commission debit = DATA-ORD-10; statistics update | one transaction; unique DATA-LEDG-02 | approved-unimplemented |
| Cancel before completion | Admin / system | DATA-ORD-01 | before delivered | cancelled | no debit | — | approved-unimplemented |
| Reassign after pickup | Admin | order, replacement captain | incident | new assignment, new PIN | only the completing captain is debited | audited | approved-unimplemented |
| Credit wallet | Admin | DATA-CRED-02 | verified transfer; resulting balance ≤ DATA-CFG-01 | ledger credit | credit | concurrent credits serialized per wallet | approved-unimplemented |
| Request deletion | captain | DATA-DEL-01 | reauth may be required; active delivery / balance rules D-P39 | DATA-DEL-03..06 | ledger kept (retention open) | request key (proposed) | domain-only |
| Register push token | device | DATA-PUSH-01/02 | session | token row | — | upsert | approved-unimplemented |

- A push or SignalR message is a hint to re-read, never state (D-A72).
- The client drops late answers (generations, session owner tag) and
  coalesces recovery reads; it never infers success from a timeout (R04).
- Proposed, not approved: `DATA-ORD-19/20` to detect stale reads.

## 6. Candidate entities and constraints (for discussion)

| Candidate | Fields | Why | Notes |
|---|---|---|---|
| `captains` (+ Identity users/roles) | DATA-USER-01..07 | D-A53, D-A65 | username/phone uniqueness open |
| `device_sessions`, `refresh_tokens` | DATA-AUTH-04/05 | D-A53, D-P03 | hashes only |
| `device_push_tokens` | DATA-PUSH-01..03 | D-A58 | contract missing |
| `captain_availability` | DATA-AV-01/03 | D-A57 | one row per captain |
| `captain_last_location` (+ optional history) | DATA-LOC-01..06 | D-A57 | retention open |
| `orders` | DATA-ORD-01..12, 17..20 | D-A44, D-A67, D-A68 | merchant/area FKs need the portal spec |
| `order_assignments` | DATA-ORD-16 | D-A67 | one active per order |
| `order_pickup_pins` | DATA-ORD-13..15 | D-A67 | hashed |
| `order_events` | DATA-ORD-07 transitions | audit | proposed |
| `offers` | DATA-OFF-01..15 | D-A46, D-A60 | — |
| `offer_decisions` | DATA-DECL-01..07 | D-A70 history | — |
| `wallets`, `ledger_entries` | DATA-WAL-*, DATA-CRED-*, DATA-LEDG-* | D-A74, D-A75 | immutable ledger; credits kept although not displayed |
| `settings` (versioned) | DATA-CFG-01..03 | D-A59, D-A75 | — |
| `idempotency_keys` | DATA-CMD-04 | D-A56 | lifetime open |
| `account_deletion_requests` | DATA-DEL-03..06 | D-A78 | D-P39 |
| `order_ratings` | DATA-RATE-04..07 | — | **unresolved**; do not create before D-P37 |
| Read models (not tables) | DATA-RATE-01..03, DATA-STAT-01/02, DATA-DELIV-*, DATA-WAL-01 if computed | convenience reads | — |
| Merchant, service area, Admin | referenced only | portal spec | **missing from this report by scope** |

**Constraints and indexes, each with its basis:**

| Constraint / index | Invariant or query | Status |
|---|---|---|
| Unique (`order`, `effect type`) on ledger | one completion debit per order (D-A74, D-A56) | approved invariant; shape proposed |
| Unique active assignment per order | one captain delivers (D-A44, D-A67) | approved |
| Unique active delivery per captain | single active delivery (D-A44) | approved |
| Credit check "resulting balance ≤ 5,000" in the same transaction | D-A75 | approved; existing over-cap balances D-P38 |
| Index (captain, offer state, expiry) | read actionable offers (D-A60) | proposed |
| Index (wallet, created at) | 7-day debit window (D-A76) | proposed |
| Unique normalized username | sign-in (D-A65) | approved |
| One open deletion request per captain | avoid duplicates | proposed; D-P39 |
| Completed-at present iff status completed | DATA-DEL-05 | proposed |

**Not tables:** cards, Cubit states, OS permission states, the 7-day window,
the derived net fee (`CaptainOrderOffer.netEarningsFils`, never shown).

## 7. Open decisions and missing contracts (by impact)

| Impact | Item | Affects | Reference |
|---|---|---|---|
| High | Earnings formula: gross fees or net after commission (lifetime period **is** decided) | DATA-STAT-02 | D-P36 |
| High | Deletion: erasure vs anonymization, ledger/identity retention, timing, session revocation, active delivery / balance / incidents | DATA-DEL-03..06, DATA-PUSH, DATA-LOC retention | D-P39 |
| High | Where the old −1,000-fils floor and other wallet conditions apply now that holds are gone | accept checks | D-P41 |
| High | Future commitments read model and its place in the product | gap | D-P25 |
| High | All OpenAPI endpoints, DTOs, Problem Details codes, SignalR events | every `in`/`out` field | D-A54, D-P02 |
| Medium | Request-key ownership and retry lifetime | DATA-CMD-04 | D-A56 (contract detail) |
| Medium | Rating scale, aggregation and who rates | DATA-RATE-* | D-P37 |
| Medium | Existing balances above 5,000 fils | DATA-WAL-01, DATA-CRED-05 | D-P38 |
| Medium | Scheduled offers accepted in the app? | DATA-OFF-03 | D-P35 |
| Medium | Terms / Privacy URLs and text | DATA-CFG-04/05 | D-P40 |
| Medium | Wallet resume freshness | trigger policy only | D-P42 |
| Medium | Password length unit (runes vs UTF-16) | DATA-AUTH-02 | `PROJECT_STATUS` §4 |
| Medium | Completed-delivery list: fields, paging, sorting | DATA-DELIV-* | — |
| Low | Location history and customer-phone retention | DATA-LOC-*, DATA-ORD-12 | privacy |
| Low | Time-zone semantics of scheduled pickup | DATA-OFF-08 | — |
| Low | App version source | DATA-CFG-06 | package approval |

## 8. Completeness crosswalk

**Screen items → fields.**

| Dynamic item | Fields / gap |
|---|---|
| Home greeting | DATA-USER-02 |
| Home balance chip, Wallet balance card | DATA-WAL-01 (one shell owner since R02) |
| Availability switch and requirement notices | DATA-AV-01, DATA-LOCAL-07 |
| Offer card and new-offer sheet | DATA-OFF-01..10 (expiry/round/mode/target/state: DATA-OFF-11..15, server) |
| Accept / decline and their notices | DATA-CMD-01..04, DATA-LOCAL-05/06 |
| Home active-order card, Current Order page | DATA-ORD-01..05 (stage/actions: DATA-ORD-06..16, not built) |
| Pickup map, captain position | DATA-ORD-03/04; captain position is a local read today (DATA-LOC-* are the approved reports) |
| My Orders declined list | DATA-DECL-01..04 (05/06 proposed) |
| My Orders completed deliveries | DATA-DELIV-01..05 — **contract missing** |
| Wallet debit history | DATA-WAL-02..08 |
| Wallet metric cards | DATA-STAT-01/02 |
| Profile name, phone | DATA-USER-02/03 |
| Profile rating | DATA-RATE-01..03 |
| Settings deletion outcome | DATA-DEL-01/02 |
| About version | DATA-CFG-06 — source missing |
| Terms / Privacy | DATA-CFG-04/05 |
| Route error, connectivity banner, No Internet | no server data (DATA-LOCAL-08) |
| Tabs, dialogs, form text, flags | DATA-LOCAL-01..04, 09, 10 |
| Future scheduled commitments | **no field yet** (D-P25) |

**Approved operations → fields.**

| Operation | Fields |
|---|---|
| Sign in / refresh / sign out / revoke | DATA-AUTH-01..07, DATA-USER-05/07 |
| Availability and location reporting | DATA-AV-01..03, DATA-LOC-01..06 |
| Offer list, accept, decline | DATA-OFF-*, DATA-CMD-*, DATA-DECL-* |
| PIN, start delivery, completion | DATA-ORD-06..16, DATA-LEDG-02 |
| Completion debit, credits, ceiling | DATA-WAL-*, DATA-CRED-*, DATA-LEDG-*, DATA-CFG-01/02 |
| Statistics, rating | DATA-STAT-*, DATA-RATE-* |
| Deletion | DATA-DEL-* |
| Push registration | DATA-PUSH-* |
| Future commitments | gap (D-P25) |

## 9a. D-A81 amendments (Current Order workflow, 2026-11-22)

Status changes of existing fields (the rows above keep their original
wording; this table is current):

| ID | Now |
|---|---|
| DATA-ORD-03/04 | `GeoPoint.isValid` also rejects `(0, 0)` (D-A62/D-P31); service-area validation stays server-side |
| DATA-ORD-06 | **domain-only**: `ActiveOrder.status` (`ActiveOrderStatus`, unknown values → `unknown`, no action) |
| DATA-ORD-08 | **domain-only**: `ActiveOrder.deliveryAreaName` (business-required; nullable in Dart only to show absence honestly) |
| DATA-ORD-12 | **domain-only, optional** (D-A81): `ActiveOrder.customerPhone`; blank → absent (`contactPhone`); never blocks start/completion; delivery leg only |
| DATA-ORD-09/10/11 | still server-side only: the app sends no amount; the debit is read back through the wallet |
| DATA-DELIV-01..05 | **domain-only**: `CompletedDelivery`, `GetCompletedDeliveries`, `CompletedDeliveriesCubit`; contract still missing |
| DATA-CMD-04 | implemented client-side as `OperationKeyFactory` (128-bit random hex); a new key per new attempt, the same key for start/complete retries after an unconfirmed outcome; **ownership and lifetime still need the API contract** |

Missing wire contracts for this feature: active-order read with stage,
assignment, area and optional phone; confirm-pickup command with its error
codes and attempts; start and complete commands with idempotency;
completion receipt; outcome lookup; completed-delivery list with paging;
the Routes access design; FCM/SignalR invalidation events for stage
changes.

## 9b. D-A82/D-A83 amendment (2026-11-24, client implemented 2026-11-24)

| Existing field | Approved target / actual implementation boundary |
|---|---|
| DATA-USER-02 | Home renders first non-empty display-name token only; full session/Profile name retained, no new API field/read required |
| DATA-WAL-01 | Wallet balance remains; Home chip, its input/selector and the eager shell read were **removed** (lazy `WalletCubit`). R02 remains the historical source-sharing fix |
| DATA-CMD-02 | Remove Home-card rejection control only; separate sheet decline and existing server/history command stay |
| DATA-ORD-08/09 | Business-required area/full fee in delivery details: `ActiveOrder.deliveryAreaName`, **`ActiveOrder.deliveryFeeFils` (added)**. Unknown displays unavailable, an explicit 0 shows 0 |
| DATA-ORD-12 | Optional phone in active delivery and the authorized own historical record; never prerequisite for Start Delivery or completion |
| DATA-ORD-22/23 | `ActiveOrder.customerName` / `deliveryNotes` (+ `contactName`, `deliveryNote`) **domain-only**, carried through stage reads and the demo; wire mapping missing |
| DATA-DELIV-01..06 | Completed list + **protected per-order page** `/order-history/completed/:orderId` reading the session's record (`recordFor`); no per-row fetch; list contract still missing |
| DATA-DELIV-07..09 | `CompletedDelivery.customerName` / `customerPhone` / `deliveryNotes` **domain-only**, from the order's own history record (demo copies the order snapshot at completion); retention/redaction unspecified |

The new details heading/labels and image semantics are localized UI, not
database fields. No customer coordinates, precise address, account or
public-offer/push personal data is introduced. The same cohesive details
presentation serves active and historical views; commands stay active-only.
Reuse a complete session-owned list record where available; otherwise a
detail read is on demand, with explicit unavailable/not-found/error states,
never N per-row fetches or polling. Exact transport/authorization/retention
contracts remain to specify. No real backend write is claimed.

The two field tables include five new atomic IDs, once per table. Earlier
125-ID counts belong to their audit snapshot; recompute a current count
from the tables instead of treating that snapshot count as a live total.

## 9. Integration backlog (bounded tasks)

| ID | Task | Inputs needed | Current boundary | Proposed files | Acceptance | Blocked by |
|---|---|---|---|---|---|---|
| B-01 | Auth/session adapter | OpenAPI auth contract, refresh/revocation rules, direct account replacement | `AuthRepositoryPlaceholder` | `data/` DTO + repository, secure storage, `get_it` registrations at the composition root (D-A64) | sign-in/refresh/revocation tests against a contract mock; no session invented; timeouts per §3.4 of `GLOBAL_SERVICES.md` | contract (D-P02, D-P03) |
| B-02 | Offers adapter | list + accept/decline endpoints, error codes, request-key ownership, expiry visibility | `OrderOfferRepositoryPlaceholder` | `data/` DTO + repository | first-accept-wins and unconfirmed mapping tests; active-order reconciliation after accept | contract |
| B-03 | Active order workflow — **client done 2026-11-22 (D-A81)** | the wire contract (§9a), Maps keys, Routes access design | client UI/state/ports done; placeholders: `ActiveOrderRepository`, `OrderWorkflowRepository`, `PickupRouteRepository` | `data/` DTOs + repositories, route adapter | contract tests: stage mapping, PIN errors/attempts, idempotent completion, outcome lookup | contract, maps keys/billing, Routes access (D-A62) |
| B-04 | My Orders completed deliveries — **client done 2026-11-22** | DATA-DELIV read model, paging/sort | `CompletedDeliveriesCubit` over the placeholder | new read model, list widget | lifetime list; declined ≠ cancelled/completed | contract |
| B-05 | Wallet / statistics adapter | balance + debits + statistics endpoints | `WalletRepositoryPlaceholder` (shared source already correct) | `data/` DTO + repository | Home and Wallet agree; unknown ≠ zero; no clamp | contract, D-P36 for earnings |
| B-06 | Rating adapter | scale, producer, aggregate | `CaptainAccountRepositoryPlaceholder` | DTO + mapping | no five-star assumption | D-P37 |
| B-07 | Availability, GPS, push | permission gateway, native setup and disclosures, report endpoint, push registration | placeholders | platform gateway, location/push services | prompts only on Available; 30 s / 90 s policy | contracts, legal copy, credentials |
| B-08 | Deletion adapter | request/status/re-auth contract | placeholder (truthful) | DTO + repository | pending ≠ completed; unconfirmed on timeout; never test against a real account | D-P39 |
| B-09 | Legal, version, release | URLs and text, version source approval, identifiers, signing | empty constant, About "unavailable" | `LegalLinks`, About | store checklist rows | D-P40, owner IDs, package approval |
| B-10 | Future commitments presentation | read model and placement | none | — | counted as a missing capability, not a screen, until designed | D-P25, D-P35 |
