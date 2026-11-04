# SHAHM (شهم) — Interactive Prototype

Client-facing prototype of the SHAHM B2B delivery operations platform, built from
**SHAHM-SRS-001 v1.0** (§19 Prototype Requirements). Arabic-first, RTL, using the
official SHAHM logo and brand palette.

> **Prototype, not production.** All data, coordinates, place-search results and
> wallet transactions are simulated and labelled as such in the UI.

## Run

```bash
npm install
npm run dev        # http://localhost:5173
npm run build      # type-check + production build
```

## What it demonstrates

| Surface | Route | Highlights |
|---|---|---|
| Landing / role picker | `/` | Demo role switching (SRS §19.5) |
| Admin Web | `/admin/*` | Dashboard with public-broadcast switch, Dispatch Center (queue, live offers, private assignment), Live Map (helmet Captain markers, store Merchant markers, live/stale/last-known/demo location states), Orders, Merchants, Captains, Service-area polygon drawing, Merchant × area pricing, Wallet recharge + ledger, Support contacts |
| Merchant Portal | `/merchant/:id` | Single screen: Request Captain (landmark autocomplete → point-in-polygon → Merchant-specific price), active orders with progress, history |
| Captain App (simulated phone) | `/captain/:id` | Availability, eligible offers with countdown, accept/reject, staged delivery, simulated trip GPS, history, wallet, support |

The **أدوات العرض** (demo tools) drawer in the top bar holds presenter-only controls:
reset data, offer policy, wallet threshold, GPS loss/reconnect, moving a Captain,
simulating a place-provider outage, and shortcuts to the five SRS §19.7 scenarios.

Open Admin, Merchant and Captain in **separate tabs of the same browser** — state
syncs between them via `localStorage`. It does not sync across devices.

## Architecture (SRS §13)

```
src/
  domain/          Pure entities & rules: types, geo (point-in-polygon, haversine),
                   money (integer fils), order state machine, eligibility, dispatch ranking
  application/     Use cases (Zustand + Immer store standing in for the backend),
                   queries (destination → area → price), ports (PlaceProvider), hooks
  infrastructure/  Seed data, mock place provider (swappable for Google/Mapbox/OSM)
  shared/          UI primitives, map components & markers, formatting
  features/        admin / merchant / captain / support / demo
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
| O-005 / O-006 offer policy & timeout | Configurable: group of 3 nearest (default) or sequential, 90 s |
| O-009 concurrent deliveries | One active delivery per Captain |
| O-012 / O-014 overlap & out-of-area | Request blocked with a clear reason |
| O-020 wallet threshold | Configurable demo threshold (2 JOD); **no debits or reservations** |
| O-029 cancellation | Admin may cancel before acceptance only, no financial effect |
| O-032 broadcast disabled | Outstanding public offers withdrawn, orders return to queue |
| O-033 rating | Internal 5-star + notes, Admin-only |
| O-034 delivery stages | All four stages mandatory, in order |

Support contacts start **empty**: official details are pending from the Product Owner.
Typography uses Tajawal as a placeholder until the brand typography is supplied.
