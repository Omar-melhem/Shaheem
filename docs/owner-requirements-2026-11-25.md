# Owner requirements of 25 Nov 2026: implementation status

Scope: the Admin and Merchant web portals (React, TypeScript, RTL). The Captain app, the backend
and the identity provider are not in this repository. Anything that needs them is listed as
**needs backend** with the contract to implement.

## Gap analysis before the change

| # | Requirement | Before this change | Now |
|---|---|---|---|
| 1 | Profit KPI, commission on delivery, 5 JOD top-up | Commission shown read-only; no debit; 500 JOD demo cap | Demo ledger: snapshot on acceptance, one debit on delivery, «أرباح شهم» card, 5 JOD cap |
| 2 | 3 rounds, 5 km → 10 km → 10 km | 3 × 60 s rounds, demo group size, no radius | Radius policy table, pickup-centred, skips empty rounds, 10 km hard limit |
| 3 | Live map: available and delivering only | All Captains, including offline | Only Available with a recent report, and delivering with live GPS |
| 4 | Idle GPS every 60 s | Tracking only during deliveries | Cadence policy + browser simulation; real reports **need the Captain app and backend** |
| 5 | No «دعم شهم» in Admin | «بيانات الدعم» page in Admin | Removed from Admin; Merchant and Captain support unchanged |
| 6 | No «مسار توصيل جديد» | Button + dialog on «مناطق التوصيل» | Removed; saved routes still listed and deletable |
| 7 | No «مرجع السبب» on top-up | Optional free-text field | Removed; idempotent operation id + receipt confirmation |
| 8 | Editable commission, password reset | Read-only rate; no reset | Confirmed + audited rate change; demo reset with one-time password |
| 9 | Optional «مجموع الطلب» | Not collected | Optional field, fils, shown in review and details; never used for fees |
| 10 | Pin anywhere inside a priced area | Pin checked against demo rectangles (edges unreliable) | Boundary-inclusive check, shared-border handling, no-boundary areas refuse pins |
| 11 | Architecture, UX, tests | — | Domain/application stay framework-free; 608 tests; RTL checked 320–1440 px |

## Consolidated master prompt (Part II, sections 12–22)

| § | Item | Status |
|---|---|---|
| A1/18 | Merchant location by map tap or search, no draggable pin | Done: non-draggable marker, unbounded search, «الموقع المحدد» summary |
| A2 | Register a merchant anywhere | Done: area boundary no longer blocks; (0,0) rejected. No pickup-service geofence exists in this codebase to enforce separately (needs backend policy) |
| A3/10 | Customer destination by tap or search, no dragging | Done |
| 12 | Login brand + original car animation | Already in place (earlier task); unchanged |
| 13 | Request form | Already in place + «مجموع الطلب» |
| 14 | Dashboard KPIs and removals | Already in place + «أرباح شهم» |
| 15 | Distribution center: right 3 queues (~65%), left offers (~35%) | Done: «بحاجة لتدخل الإدارة» moved into the right column |
| 16 | Merchant sidebar, logout in Settings with confirmation | Already in place |
| 17 | Compact password reset | Done: role + search, account + button, compact disclosure; stale selection dropped |
| 19 | Tables, filters, dropdown | Already in place |
| 20 | Responsive | Checked 320, 375, 390, 430, 768, 1024, 1280, 1440, 1920, 2560 px: no page overflow, no runtime errors |
| 22 | External Claude Code tools | Not installed (owner approval required) |

## What runs where

| Concern | Layer | Files |
|---|---|---|
| Commission maths, top-up cap, ledger sums, holds | domain | `domain/commission.ts`, `domain/wallet.ts` |
| Top-up, lock, settle, rate change | application | `application/walletLedger.ts` (called from `store.ts`) |
| Revenue by Amman day / month | application | `application/dashboard.ts` → `commissionRevenue` |
| Round policy and candidate selection | domain | `domain/dispatch.ts` (`DISPATCH_ROUNDS`, `selectRoundCandidates`) |
| Round engine | application | `application/dispatchRounds.ts` |
| Location cadence, freshness, map presence | domain | `domain/location.ts` |
| Idle-report simulation | application | `application/locationReports.ts` (demo stand-in for the Captain app) |
| Password reset | application + infrastructure | `application/accountAdmin.ts`, `infrastructure/credentials.ts` (wired in `app/state.ts`) |
| Order total | domain | `domain/orderTotal.ts` |
| Pin containment | domain | `domain/geo.ts` (`polygonCovers`), `domain/destination.ts` |
| Saved-data upgrade | infrastructure | `infrastructure/browserState.ts` (`migrateAppData`) |

## Data compatibility

- Saved browser data from before this change is **upgraded, not reset**: `adminAudit: []` and
  `settings.commissionBp = 2000` are added; every order and wallet entry is kept as saved.
  `STORAGE_KEY` stays `shahm-demo-v9`.
- Orders accepted before this change have no commission snapshot and are **never charged**.
- Old recharges keep their typed reason; new ones have none.
- Old orders without «مجموع الطلب» show «غير مضاف».
- Removed demo settings `offerPolicy` / `groupSize` are ignored if still present in saved data.

## Needs backend (contracts)

### §1 Ledger and commission
See `wallet-commission-backend-contract.md`. One database transaction per use case, unique
`idempotency_key`, at most one `commission_debit` per order, append-only ledger.

### §2 Dispatcher
A persisted job owns `round_started_at` / `round_expires_at` per order, offer creation within the
radius (PostGIS `ST_DWithin` on geography from the Merchant pickup), and atomic acceptance
(`UPDATE … WHERE status = 'awaiting_captain' AND captain_id IS NULL`). A page timer is never the
clock. Broadcast OFF withdraws open public offers and starts no new rounds.

### §4 Captain location ingest
`POST /captains/me/location { lat, lng, accuracyM, recordedAt }`. The server stores `receivedAt`,
rejects invalid or (0,0) coordinates and keeps the latest per Captain. The app sends every 60 s when
Available with no delivery and every 30 s during a delivery, and stops when unavailable. The Admin
map reads `GET /admin/captains/live` (Admin role only) and treats a position older than 90 s as
stale. Mobile OS background limits apply: the cadence is a target, not a guarantee.

### §8 Password reset
`POST /admin/accounts/{role}/{id}/password-reset` (Admin role, rate-limited). ASP.NET Identity
`GeneratePasswordResetTokenAsync` + `ResetPasswordAsync`, or a one-time credential the user must
change at first sign-in. Revoke the account's sessions and refresh tokens. Audit actor, target and
time, never a password. The demo keeps credentials in the browser and cannot revoke other tabs'
sessions.

### §10 Area boundaries
Each enabled destination needs an authoritative, validated polygon/multipolygon (SRID 4326,
versioned). The server must repeat the check with `ST_Covers` (boundary-inclusive) against the
Merchant's own covered and priced areas. The demo rectangles in `infrastructure/seed.ts` are
**approximate placeholders**: they are not the real boundary of أم أذينة or any other area.

## Open owner decisions (implemented as labelled assumptions)

1. Top-up cap «5»: implemented as **5.000 JOD per transaction**, not a balance cap.
2. «3 إلى 5 كيلو»: implemented as **3 Captains within 5 km**, not a 3–5 km band.
3. Round 2 size: **3** (proposed).
4. Rounds 2 and 3: **60 s** each (proposed).
5. Commission range: the existing **0–100%**; default 20%; rounding half up to the fils (proposed).
6. Hold on acceptance, debit on delivery: implemented as previously documented.
7. Reset credential handoff and session revocation: demo shows a one-time password; production flow open.
8. Who may read the customer pin besides Admin (Captain navigation scope): open.
9. Active-delivery cadence: kept at 30 s.
10. Authoritative boundary source for each area, including أم أذينة: open.
11. Admin no longer has a page to edit «دعم شهم» contacts. The stored list (empty in the seed) still
    feeds the Merchant and Captain views; a future change must decide who maintains it.
