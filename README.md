# SHAHM (شهم) — Interactive Prototype

Client-facing prototype of the SHAHM B2B delivery operations platform, built from
**SHAHM-SRS-001 v1.0** (§19 Prototype Requirements). Arabic-first, RTL, using the
official SHAHM logo and brand palette.

> **Prototype, not production.** All data, coordinates, place-search results and
> wallet transactions are simulated and labelled as such in the UI.

## Run

Requires Node.js 20 or newer.

```bash
npm install
npm run dev        # http://localhost:5173
npm test           # business-rule checks (tests/logic.test.ts)
npm run build      # type-check (src + tests) + production build
```

## What it demonstrates

| Surface | Route | Highlights |
|---|---|---|
| Login | `/login` | Minimal username/password sign-in (validation, show/hide password, loading state) with a faint logo watermark; labelled demo-accounts shortcut for presenters |
| Admin Web | `/admin/*` | Dashboard (Overview: 8 KPI cards, latest orders with View details / Cancel, then alerts), Dispatch Center (60 s × 3 public rounds → Admin queue, private assignment), Captain-only Live Map with Captain details, Orders, Merchants, Captains, Delivery Zones (Governorate → Area polygons + origin → destination routes), Merchant Pricing (merchant cards → that merchant's zone prices), Wallet recharge + ledger, Support contacts, **Settings** (`/admin/settings`) |
| Merchant Portal | `/merchant` | Single screen: Request Captain (searchable destination list + map pin → detected zone → fixed, read-only fee; required order value; optional customer name and phone), active orders, history |
| Merchant Settings | `/merchant/settings` | Read-only profile, business category, pickup location, zone prices, account, SHAHM support |
| Captain App (simulated phone) | `/captain` | Availability, eligible offers with countdown, accept/reject, staged delivery, simulated trip GPS, history, wallet, support |

Demo credentials: `admin / admin1234`, `merchant1…merchant6 / demo1234`, `captain1…captain8 / demo1234`.
Each browser tab keeps its own sign-in (sessionStorage), so Admin, Merchant and Captain can be open side by side.

### Pricing model (Merchant Zone-Based Pricing Spec)

Admin maintains one central list of delivery zones (with aliases, no duplicates) and,
per merchant, enables zones with a fixed full delivery fee. The merchant searches for
the customer's place (OpenStreetMap) or taps the map; the zone is detected from the pin
using the zone boundaries, and the fee is shown read-only and locked onto the order at
confirmation (`pricingSnapshotAt`). Pricing is never distance-based.
If the fee changes while the form is open, the merchant must re-confirm the new fee.

The floating **أدوات العرض** (demo tools) button holds presenter-only controls:
reset data, offer policy, wallet threshold, GPS loss/reconnect, moving a Captain,
and the demo scenarios.

Open Admin, Merchant and Captain in **separate tabs of the same browser** — state
syncs between them via `localStorage`. It does not sync across devices.

## Architecture (SRS §13)

```
src/
  domain/          Pure entities & rules: types, geo (point-in-polygon, haversine),
                   money (integer fils), order state machine, eligibility, dispatch ranking
  application/     Use cases (Zustand + Immer store standing in for the backend),
                   queries (merchant + zone → fixed fee), session, hooks
  infrastructure/  Seed data
  shared/          UI primitives (one per file in components/ui/), logo & watermark, map components, formatting
  features/        auth / admin / merchant / merchants (category) / captain / support / demo
  app/             Routing and shell
```

UI components never own pricing, dispatch, wallet or transition rules — they call
use cases that return `Result` values. In production each use case becomes an
authenticated, server-validated API call (shared DB, PostGIS, realtime, push).

## Demo assumptions for open decisions

Each is labelled in the UI with its SRS decision ID and none is an approved rule:

| Decision | Prototype behaviour |
|---|---|
| O-001 pre-trip Captain location | Seeded/presenter-set "demo" positions, never shown as live |
| O-004 distance method | Straight-line (haversine) to the Merchant pickup |
| O-005 offer policy (who receives each round) | Configurable: group of 3 nearest (default) or sequential. Round length (60 s) and the 3-round cap are owner-confirmed (Feature Updates v1.2) |
| O-006 private offer timeout | Configurable, default 60 s |
| FU §14.5–14.7 routes & area catalogue | Routes are records only (no pricing effect); governorates = Jordan's 12 |
| O-009 concurrent deliveries | One active delivery per Captain |
| Customer location | Place search (OpenStreetMap/Photon, O-018 provider open) or map tap; exact pin saved on the order; zone detected from the pin |
| O-020 wallet threshold | Configurable demo threshold (2 JOD) |
| Captain commission (CR v1.3 §6) | JOD 0.200 per delivered order is approved but **not implemented**: it needs a transactional backend. See `docs/wallet-commission-backend-contract.md` |
| O-029 cancellation | Admin may cancel before acceptance only, no financial effect |
| O-032 broadcast disabled | Outstanding public offers withdrawn, orders return to queue |
| O-033 rating | Internal 5-star + notes, Admin-only |
| O-034 delivery stages | All four stages mandatory, in order |
| OPEN-FE-07 business categories | Proposed list (restaurant, café, retail, grocery, pharmacy, bakery, other); classification only; legacy records show «غير مصنّف» |
| OPEN-FE-03 / 05 / 06 | No password reset; Merchant settings are read-only; only Admin sets a Merchant's category |

Support contacts start **empty**: official details are pending from the Product Owner.
Typography uses Tajawal as a placeholder until the brand typography is supplied.
