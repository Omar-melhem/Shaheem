# SHAHM — Product Overview (for the Flutter app)

The product context and business rules the Flutter app must respect. Each
rule names its **source** and **status**. Nothing here is implemented in
Flutter unless `PROJECT_STATUS.md` says so.

**Canonical decision precedence:** The owner approvals recorded through 2026-11-14 supersede contradictory 2026-11-10/12 prototype notes. These requirements describe intended behavior, **not implemented code**; verify actual implementation in `PROJECT_STATUS.md`.

**Sources:**
- The Flutter project guidelines (the `CLAUDE.md` versions supplied on
  2026-11-10; see `../archive/OLD_REQUIREMENTS/`).
- The web prototype's approved rules (`../../../web_frontend/CLAUDE.md` and
  `../../../web_frontend/docs/SHAHM-PROJECT.md`, built from SHAHM-SRS-001 v1.0,
  Feature Updates v1.2, CR v1.3 and CR v1.4).

---

## 1. Identity

| | |
|---|---|
| Name | SHAHM (Arabic: شهم) |
| Purpose | B2B delivery operations: merchants request delivery captains; an Admin runs dispatch, merchants, captains and wallets |
| UI language and direction | Arabic, RTL |
| Default geography | Amman, Jordan |
| Currency | Jordanian Dinar (JOD, د.أ), stored as integer fils |

## 2. Roles

| Role | Responsibilities |
|---|---|
| Admin | Manages merchants, captains, orders, wallets, dispatch, zones and pricing |
| Merchant | Creates delivery requests and tracks them |
| Captain | Receives offers, accepts and completes deliveries, manages availability, sees wallet and history |

**Flutter app scope (Approved, D-A42):** the Flutter mobile app serves
**captains only**. Admin and Merchant remain roles in the wider SHAHM system,
but their interfaces are outside this app's scope. Do not add Admin or
Merchant routes, navigation destinations or screens to this Flutter app.
This does not define the backend profile schema. ASP.NET Identity is the
approved identity direction (D-A53, ledger D-P02), but the concrete
authentication/profile DTOs are not yet written; retain the existing optional
`AppUser.role` field and adapt it when that OpenAPI contract is specified
(D-A42).

**Backend architecture (owner-approved 2026-11-14):** ASP.NET Core Web API,
ASP.NET Identity, PostgreSQL/EF Core (Npgsql), REST `/api/v1`, OpenAPI, typed
Dart/TypeScript clients after generator verification, and task-oriented
commands for sensitive order transitions. The two web portals are separate;
Flutter is for captains only. All apps share the same authoritative backend.
SignalR carries foreground realtime updates; FCM/APNs deliver mobile push;
PostgreSQL is the system of record. A lightweight transactional outbox protects
critical business-event emission. These are **future implementation contracts**;
there is no implemented backend in the supplied Flutter snapshot.

## 3. Business rules

Status values:
- **Approved:** confirmed in a requirement source.
- **Prototype assumption:** used for demos; not a final policy.
- **Pending:** awaiting a Product Owner decision.

### 3.1 Order states (owner-approved)

Exact delivery state values:
`pending_dispatch`, `awaiting_captain`, `offered_privately`, `accepted`,
`heading_to_pickup`, `picked_up`, `on_the_way`, `delivered`, `cancelled`,
`dispatch_expired`.

- Valid active-delivery sequence: `accepted` → `heading_to_pickup` →
  `picked_up` (merchant gives the **order-specific four-digit pickup PIN** to
  the captain) → `on_the_way` (**separate Start Delivery action**, after the
  captain calls the customer outside SHAHM) → `delivered`.
- Backend alone verifies permissions, guards, and state transitions. Task-based
  POST commands are used for accept, pickup PIN, start delivery, completion,
  cancellation and reassignment; PATCH applies only to ordinary editable data.
- Each order has at most one assigned captain at any moment. Admin can reassign
  the *same* order in auditable exceptional flows without simultaneous owners.
- Each captain has at most one **active delivery**: `accepted`,
  `heading_to_pickup`, `picked_up`, or `on_the_way`. A confirmed future
  scheduled commitment is separate from this active-delivery count; its
  detailed storage/read-model transition must be made explicit in the backend
  contract to avoid accidentally blocking instant orders days in advance.
- Only the captain currently responsible can mark an order delivered. There
  is no customer OTP, photo or signature for delivery.
- Customer is not a registered SHAHM user and has **no** app, account, name,
  GPS point, precise address or customer-facing route. Only the customer phone
  and destination **area** are entered by the merchant.

### 3.2 Captain eligibility (owner-approved)

- Account is active; profile is complete as required for dispatch.
- The captain is **Available** with required location **and push** permissions.
  Android uses a foreground location service while tracking; iOS uses its
  authorized background location mode, subject to OS restrictions. If either
  required permission is missing or revoked, availability/offer eligibility is
  withdrawn. Permission requests occur when enabling Available, not startup.
- Location reports target **every 30 seconds** when Available; a fix must
  have reported accuracy **within 100 metres**. A server-
  received valid fix is dispatch-fresh for **90 seconds**, using the backend
  clock, not the phone clock alone. After 90 seconds without a valid report,
  the captain is excluded from new offers; the active delivery is unaffected.
  The last known location/time and staleness warning remain visible to Admin.
  Durations are configurable on the server. The OS may delay background fixes.
- One active delivery maximum. Scheduled future commitments are independent;
  new instant offers stop **approximately 30 minutes** before a scheduled
  pickup. Admin receives a possible conflict warning **one hour** beforehand;
  no fixed gap is imposed between future commitments.
- In one atomic acceptance/assignment transaction, the backend tests that
  **available balance after the proposed commission hold ≥ -1,000 fils**.
- A private offer is visible only to the targeted captain. The backend checks
  all eligibility conditions again at acceptance. Valid offers may expire or
  be withdrawn; an old push is not permission to accept.

### 3.3 Wallet and commission (owner-approved D-P10)

| Rule | Final business contract |
|---|---|
| Currency | Store monetary amounts in **integer fils**; never binary float |
| Delivery fee | Fixed at order creation for the chosen destination area, in **0.500 JOD** increments; not derived from map distance |
| Global rate | **20%** initially; one Admin-adjustable rate for all captains, no captain-specific percentages; existing orders keep their snapshot |
| Commission | Percentage of **delivery fee only**, calculated precisely with decimal/integer arithmetic and **rounded to nearest fils** |
| Snapshot | First public dispatch for automatic instant orders; first confirmed private acceptance/assignment for direct instant orders; **Admin confirmation of scheduled assignment** for scheduled orders. Store percentage and amount immutably |
| Reserve/hold | On captain acceptance for instant offers, or on Admin confirmation of scheduled assignment, hold only the commission, not the entire delivery fee. An automatic public broadcast itself is **not** a captain wallet hold |
| Balance | Confirmed external recharge credits − final commission debits (plus audited explicit adjustments, if any) |
| Available | Balance minus active holds; prospective Available after a new hold cannot fall below **-1,000 fils** |
| Delivery completed | Convert the existing hold into **one** permanent `commission_debit`, do not debit twice |
| Cancel before pickup | Release the hold, no automatic fine |
| Cancel/reassign after pickup | Admin-only exception, **do not automatically release or debit** while unresolved; mark pending settlement. On an approved direct handover to replacement captain, release outgoing hold as the audited transfer, place replacement captain's hold under the configured wallet rules, and charge only the replacement captain on delivery. Any compensation is a separate audited manual adjustment |
| Recharge | Captain arranges external transfer (CliQ, e-wallet, bank), Admin verifies receipt and records credit. No integrated payment or captain self-credit. A credit offsets negative balance first; notify captain |
| Ledger | Immutable append-only journal; preserve operation identities and unique financial-effect constraints so retries never duplicate top-ups, holds, releases or debits |

Business changes and wallet operations require atomic PostgreSQL transactions,
server-side authorization, idempotency keys on retriable mutations, and an
immutable financial audit trail. Pending post-pickup settlement cases remain
visible to Admin; no indefinite silent holds. Display wallet balance,
available balance, active holds and ledger to the captain; all values come from
Backend.

**Implementation boundary:** The earlier web file
`web_frontend/docs/wallet-commission-backend-contract.md` exists in the
repository, but it was not included in the 2026-11-14 reconciliation bundle
and has not been reviewed line by line. Its content is **not** hereby
certified or automatically approved. Concrete DTOs/endpoints and ledger
constraints must be written against these owner-approved business rules.

### 3.4 Dispatch (owner-approved)

**Global Broadcast switch is the Admin's primary manual-control tool.**
- **ON:** new instant requests enter public automatic broadcast.
- **OFF:** atomically stop new public dispatch, withdraw **all unaccepted
  public offers**, reject subsequent attempts to accept those offers even if
  a push remains on a phone, and return unassigned orders to the Admin manual
  queue. Accepted/in-progress orders are unaffected. Admin's private offers
  continue in both switch states. Scheduled orders are outside this switch.
- After re-enabling broadcast, previously queued manual orders **remain
  manual** unless Admin explicitly sends them back to public dispatch.
- No separate per-order "withdraw from broadcast" UI is required in MVP.

**Public dispatch rounds (per immediate order):**
1. Round 1: simultaneous offer to the nearest **three new eligible captains
   within 5 km**, for **60 seconds**.
2. Round 2: simultaneous offer to the next **three new eligible captains
   within 10 km**, for **60 seconds**.
3. Round 3: offer to **all remaining eligible captains in the city** for **60
   seconds**, not merely three captains.

Offers from earlier rounds remain eligible until the third round ends (unless
rejected, accepted by someone else, or withdrawn globally); do not notify the
same captain twice for one offer. Skip empty candidates promptly; when only
one or two qualify in an early round, offer to those and run that round. The
first valid **atomic backend acceptance** wins and invalidates all other
outstanding offers. After the third round the order enters Admin's queue with
`dispatch_expired`. Initial distance tiers are approved; future configuration
may be introduced via server/Admin settings, without client hardcoding.

**Private offers:** one targeted captain at a time, valid **two minutes**.
A refusal/expiry returns the order to Admin without automatic cascade or
public rebroadcast. Server validation at accept time is mandatory.

**Scheduled orders:** Always manual via Admin's WhatsApp group. Admin records
one volunteer as confirmed assignment (no second in-app acceptance), captures
the commission snapshot and hold immediately, and shows it as a future
commitment, not an active delivery. Multiple commitments can coexist; Admin
checks schedules manually. New instant offers stop around 30 minutes before
pickup; Admin receives a conflict warning one hour beforehand. No automatic
WhatsApp integration, automated volunteer deadline or scheduled broadcast is
approved for MVP. The exact manual response deadline remains **unspecified**;
Admin can explicitly close a WhatsApp request.

### 3.5 Pricing, geographies and merchant pickup coordinates

- Admin manages hierarchy: Governorate → City → Area → optional subdivision.
  Each enabled destination zone has an explicitly configured delivery fee,
  in **0.500 JOD increments**. Snap the fee onto each order at creation.
- Merchant pickup latitude/longitude must be finite, geographically valid,
  **not (0,0)**, and **inside an Admin-enabled service-area geofence** in the
  Backend database. No Jordan-only boundaries hardcoded into Flutter or API.
- Admin sets/repairs the merchant's pickup map pin. Merchant cannot create
  an order if pickup coordinates are invalid or outside the enabled service
  area. If coordinates become invalid for an **already-active** order, keep
  the order visible, show an explicit location error, and disable only the
  pickup map rather than substituting fake coordinates.
- Customer location is an **area**, never a GPS point or route.

### 3.6 GPS, maps and push

- Target location upload cadence 30 seconds, accuracy within 100 metres,
  and dispatch validity 90 seconds;
  check location freshness server-side. Admin sees last reported fix/time.
  Background tracking continues best-effort while Available or on active
  delivery; stop when neither applies. GPS failure never cancels active work.
- App requests precise/required background location and push permissions when
  captain switches to Available, not at startup. Availability is refused or
  revoked when permissions are missing; permissions may be requested in stages
  consistent with Android/iOS policy. Confirm real device behavior.
- `location` + `permission_handler` behind `LocationRepository`, so the
  provider remains swappable. Android foreground service notification and
  proper iOS background mode/configuration are required.
- Google Maps in Flutter shows **captain → merchant pickup** only; Google
  Routes API Essentials DRIVE supplies road distance/ETA (without live
  traffic). Provide a separate **Open in Google Maps** native-navigation
  action for heading to pickup. Never draw a route to the customer.
- FCM (plus APNs on iOS) transports push; PostgreSQL is authoritative for
  notification history and unread count. New-offer push shows pickup area,
  destination area and delivery fee only; never customer phone or identity.

### 3.7 Identity, credentials and sessions

- Username + password; no email login and no self-registration. Admin creates
  accounts, completes missing profiles, resets passwords and handles support.
- Username: **4–30 ASCII** letters, digits, underscore or dot; case-
  insensitive on Backend. The optional normalized ten-digit phone number may
  serve as username: when it is typed with Arabic-Indic or Extended
  Arabic-Indic digits (in any mix with Latin digits), convert them to Latin
  digits before validation and submission, keeping the leading zero; never
  strip a country code or accept new separator formats (D-A65 supplement).
  Trim only **leading/trailing username whitespace** on
  submission; do not change interior characters/case or **ever trim password**.
- Password: **8–128 characters**, spaces permitted, without arbitrary
  composition rules. Common/weak passwords are rejected by the **backend when
  an Admin creates or resets a password**, not at sign-in (D-A65 supplement;
  the backend policy/list is still to be specified). Do not log/store
  plaintext password in state, diagnostics or error messages.
- Exact Arabic field messages for the length and character rules are
  recorded in the D-A65 supplement.
- ASP.NET Identity handles accounts/roles/password hashing. Access JWT life:
  **15 minutes**; rotated hashed refresh tokens with **90-day inactivity
  expiry** (reset on authenticated use); access token in memory and refresh
  token in `flutter_secure_storage`. Only **one device session per captain**;
  a new sign-in revokes the older session but does not cancel active work.
- Suspended/blocked users lose API and refresh access immediately; client
  ends their session and returns to Login. Admin handles in-progress delivery.
  Treat unknown connection errors as transient, not as logout.
- Phone numbers normalized to 10 local digits (Arabic-Indic digits to Latin,
  leading zero preserved) as required by the existing product rule.
- Login wrong credentials use a generic message. Forgot password and no-
  account actions direct the user to contact Admin; no public registration
  or automatic reset in MVP.

### 3.8 Captain app navigation

- Exactly five bottom destinations: **Home**, **Notifications**, **Current
  Order** (center), **Order History**, **Wallet**; Wallet replaces the old
  Profile tab. Profile access is moved to the AppBar/menu, not deleted.
- AppBar shows the **total wallet balance**; Wallet shows balance, available,
  holds and immutable transaction history.
- Backend/PostgreSQL owns notification unread count; Notifications Cubit
  supplies the navbar dot. Server owns current active-order existence; the
  center indicator is refreshed on sign-in, acceptance, relevant order changes,
  verified push, app resume and when opening Current Order, **not polling**.
- Current Order never creates an order or displays a customer's route.
- Device display name: Android/iOS **«شهم»**; web title **«SHAHM | شهم»**;
  internal package identifiers need not be renamed.
- These are **approved target requirements**; the uploaded Flutter source
  snapshot may still contain Profile/placeholder screens.

### 3.9 Current Order and pickup map

- `GET` from Backend returns the **one** current active delivery or no active
  delivery. The client never infers an order from stale push/local state.
  Exact DTO names/endpoints must be verified in OpenAPI before implementation.
- The active response includes authoritative order id/status, merchant name,
  pickup coordinates, optional pickup instructions and relevant stage actions.
  Scheduled future commitments appear separately until activated for delivery.
- Render merchant pickup map as soon as an active delivery is assigned/
  accepted. Missing/invalid pickup coordinates do **not** hide an active
  order, only disable the map and show an explicit explanation.
- Merchant pickup PIN is unique **per order**, **four digits**, shown only to
  merchant and communicated verbally after physical handover. Backend
  validates order, assignee, stage, and up to **three failed attempts**, then
  Admin intervention; PIN is single-use, invalid when cancelled/expired, and
  regenerated on reassignment before pickup.
- A separate **Start Delivery** action advances `picked_up` → `on_the_way`.
  No call recording is required. Captain alone marks delivered when permitted.
- Google Maps and Routes API DRIVE route **only to merchant**; separate
  native Google Maps navigation action is available on pickup leg.

### 3.10 Deliberately excluded (Product Owner decisions, web)

- No customer-name field.
- No goods value on new orders.
- No merchant contact person.
- No captain vehicle data.
- No invented support phone numbers, emails or WhatsApp links.


### 3.11 Post-pickup incidents (Admin only)

- After merchant pickup, captain cannot cancel independently; the captain
  immediately contacts Admin for danger, accident or inability to complete.
- Admin may cancel, settle or reassign **the same order** to a replacement
  captain after coordinating a real-world goods handover; keep full actor,
  timestamp and assignment history.
- Never automatically release/charge commission merely because an incident
  was reported after pickup. Mark unresolved cases **pending settlement**.
- On confirmed transfer, release outgoing captain's held commission as an
  audited reassignment action, create/check replacement captain's hold, and
  charge **only the replacement captain** on final delivery. Any outgoing-
  captain compensation or correction is separate manual audited accounting.
- Goods/cash exchange and claims remain Admin-managed outside MVP app.

### 3.12 Vehicles and routing

- Deliveries use **cars only**. Google Maps pickup map and Google Routes API
  Essentials DRIVE estimate merchant-road distance/ETA without live traffic.
- No customer coordinates, street-level destination, or turn-by-turn in-app
  navigation to customers. Native Google Maps is available only as a
  separate action **to merchant pickup**.

## 4. Remaining technical specifications / verification (not new owner approvals)

The major owner decisions are approved. These tasks remain to be **specified
or verified**, not silently implemented as unapproved behavior:

1. Write and validate the detailed `/api/v1` OpenAPI DTOs/authorization/error
   contracts; use Problem Details RFC 9457 with stable business codes,
   type-safe clients, contract tests, and a separate SignalR event catalog.
2. Model the **scheduled future commitment versus active delivery** explicitly
   without inventing a new order state or causing duplicate active orders.
3. Implement server-side atomic wallet holds/settlements, unique ledger
   operation keys, post-pickup pending settlement work queue, idempotency
   rules and PostgreSQL transactional outbox for critical events.
4. Specify the Admin-controlled closing time for manual WhatsApp volunteer
   requests if a fixed automated deadline is ever needed; none is approved.
5. Validate platform GPS/notification behavior on physical Android/iOS, map
   billing/API restrictions, security tests, and complete dependency audit.
6. Review the separate, **not yet reviewed** web wallet backend contract
   (present in the repository, not in the 2026-11-14 bundle) before
   claiming that *that particular document* has been approved.

**Source-of-truth rule:** older `D-Axx` or prototype implementation notes
remain historical when superseded by the explicit owner approvals through
2026-11-14. `PROJECT_STATUS.md` records what is actually present in code.
