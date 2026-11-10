# Captain wallet and commission: backend contract

**Status: not implemented.** This repository has no backend, so no commission is charged anywhere.
The prototype keeps all data in browser storage, which Change Request v1.3 forbids as the source of
truth for balances and debits. `src/domain/commission.ts` holds the approved amount for display only.

**Approved rule (CR v1.3 §6):** Admin credits a Captain's wallet after payment outside the system.
Each delivered order then debits the Captain a **percentage of that order's delivery fee**
(CR v1.4 §3, proposed 20%: a JOD 1.500 fee → JOD 0.300). It is never a flat amount and never
uses the goods value. Admin can change the percentage for future assignments only. The
calculation already exists in `src/domain/commission.ts` (`commissionFils`, basis points,
integer fils, round half up) and is covered by `npm test`; the backend should reuse the same rule.

## Data model (PostgreSQL example; adapt to the chosen stack)

```sql
CREATE TABLE commission_settings (
  id             BIGSERIAL PRIMARY KEY,          -- append-only; the latest row is effective
  commission_bp  INTEGER NOT NULL CHECK (commission_bp BETWEEN 0 AND 10000), -- 2000 = 20%
  updated_by     UUID NOT NULL,
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE delivery_orders
  ADD COLUMN commission_snapshot_bp INTEGER,                 -- rate at acceptance
  ADD COLUMN commission_snapshot_fils INTEGER CHECK (commission_snapshot_fils >= 0); -- fee snapshot × rate; NULL = none

CREATE TABLE wallet_ledger (                     -- immutable: no UPDATE or DELETE
  id              UUID PRIMARY KEY,
  captain_id      UUID NOT NULL REFERENCES captains(id),
  order_id        UUID REFERENCES delivery_orders(id),
  type            TEXT NOT NULL CHECK (type IN
                    ('admin_recharge','commission_debit','hold','hold_release','admin_adjustment')),
  amount_fils     BIGINT NOT NULL,               -- signed: credits > 0, debits and holds < 0
  actor_id        UUID,
  reason          TEXT,
  idempotency_key TEXT NOT NULL UNIQUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- At most one commission debit per order, whatever is retried.
CREATE UNIQUE INDEX one_commission_per_order
  ON wallet_ledger (order_id) WHERE type = 'commission_debit';
```

- **Balance** = the sum of `admin_recharge`, `commission_debit` and `admin_adjustment` entries.
- **Available** = balance minus holds that have not been released or converted.
- Use integer fils only. Keep a per-Captain `wallet_accounts` row to lock while posting.

## Use cases (each in one database transaction)

| Use case | Steps |
|---|---|
| `AcceptOffer` / `AssignCaptain` | Lock the Captain's wallet row and the order. Read the current commission and store it in `commission_snapshot_fils`. Reject if available funds are below it. Post a `hold`. Assign the order. |
| `CompleteDelivery` | Lock the order. If it is already delivered, return success with no new entries. Verify the assigned Captain. Set `delivered`. Post `hold_release` and `commission_debit` for the snapshot. |
| `CancelOrder` (before completion) | Post `hold_release`. No commission. |
| `RechargeWallet` | Admin only. Post one `admin_recharge` using a client-generated idempotency key. |
| Correct a mistaken recharge | Post a new `admin_adjustment` with reason and actor. Never edit or delete history. |
| `SetCommission` | Admin only. Insert a settings row and an audit record. Affects future assignments only. |

Idempotency keys: `commission:{orderId}`, `hold:{orderId}:{captainId}`, `release:{orderId}:{captainId}`.

## API endpoints needed

All are server-authorised by role. Names are proposals; none exist yet.

- `GET /captains/:id/wallet`, `GET /captains/:id/wallet/transactions`
- `POST /captains/:id/wallet/recharges`, `POST /captains/:id/wallet/adjustments`
- `GET /settings`, `PUT /settings/commission`
- `POST /offers/:id/accept`, `POST /orders/:id/assign`, `POST /orders/:id/complete`, `POST /orders/:id/cancel`

## Rollout

1. Deploy the schema with no behaviour change. Create opening `admin_recharge` entries from verified balances only.
2. Orders already accepted at switch-on keep `commission_snapshot_fils = NULL` and are **never charged**.
3. Turn on snapshot, hold and debit for new assignments.

**Rollback:** disable the feature flag so new assignments stop taking holds, and release outstanding
holds with `hold_release` entries. Keep the ledger rows.

## Tests required before production

- At 20%: fees of 1.000 / 1.500 / 0.750 JOD post 0.200 / 0.300 / 0.150 JOD; a 5.000 wallet after those three holds 4.350.
- Repeated and concurrent `CompleteDelivery` calls produce exactly one debit.
- Two simultaneous acceptances cannot reserve the same funds.
- Cancelled, rejected and expired offers post no commission.
- A commission change does not affect orders that were already accepted.
- Pre-rollout orders are not charged.
- Ledger totals reconcile with balances.
- Non-Admin users cannot recharge or change the commission.

## Decisions needed from the Product Owner

1. **Hold at acceptance:** the recommended design above. Is it approved?
2. **Private assignment:** can Admin assign a Captain who lacks funds? Default: no.
3. **Old eligibility threshold (O-020, JOD 2.000 demo value):** replace it with "available funds cover the commission", or keep both?
4. **Admin-completed orders:** if Admin may mark an order completed, the same once-only debit applies. Is that path allowed?
5. **Reopened or reversed completion:** does it refund the commission through an adjustment entry?
6. **Zero commission:** is it allowed as a deliberate waiver?
7. **Finance role:** is recharging limited to Admin, or is there a separate finance role?
