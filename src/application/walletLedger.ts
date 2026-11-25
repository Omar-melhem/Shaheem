import type { DeliveryOrder, ID, Money } from '@/domain/types';
import { COMMISSION_RATE_ERROR, commissionFils, isValidCommissionBp } from '@/domain/commission';
import { commissionKey, rechargeKey, topUpAmountError } from '@/domain/wallet';
import { ADMIN_ACTOR, SYSTEM_ACTOR, type AppData } from './data';
import { uid } from './orderMutations';
import { done, fail, ok, type Result } from './result';

// Wallet and commission use cases, run inside one store update (immer draft) so the order and its
// ledger entry change together. That is the demo's unit of work only: production needs one
// database transaction with unique keys (docs/wallet-commission-backend-contract.md).

/**
 * Admin top-up after verifying the payment outside the system. One entry per `operationId`: a
 * retried or double-clicked confirmation returns the first result and never credits twice.
 * There is no free-text reason any more (owner, 2026-11-25); the entry keeps its id, key, actor
 * and time.
 */
export function rechargeCaptainWallet(d: AppData, now: number, captainId: ID, amount: Money, operationId: string): Result<{ duplicate: boolean }> {
  if (!d.captains.some((c) => c.id === captainId)) return fail('الكابتن غير موجود');
  if (!operationId.trim()) return fail('تعذّر تسجيل العملية، أعد المحاولة');
  const key = rechargeKey(operationId);
  const existing = d.walletTx.find((t) => t.idempotencyKey === key);
  if (existing) {
    return existing.captainId === captainId && existing.amount === amount ? ok({ duplicate: true }) : fail('رقم العملية مستخدم لعملية أخرى');
  }
  const amountError = topUpAmountError(amount);
  if (amountError) return fail(amountError);
  d.walletTx.unshift({ id: uid('tx'), captainId, type: 'recharge', amount, createdAt: now, actor: ADMIN_ACTOR, idempotencyKey: key });
  return ok({ duplicate: false });
}

/** Locks the current rate and amount on the order when a Captain accepts. Later rate changes never touch it. */
export function lockCommission(d: AppData, order: DeliveryOrder) {
  if (order.commissionFils !== undefined) return;
  order.commissionBp = d.settings.commissionBp;
  order.commissionFils = commissionFils(order.deliveryPrice, d.settings.commissionBp);
}

/**
 * Turns the order's held commission into its single debit when it is delivered. Idempotent: a
 * retried completion finds the existing `commission:{orderId}` entry and adds nothing. Orders
 * accepted before commission existed have no snapshot and are never charged. A low balance never
 * blocks the delivery; the balance may go negative and the eligibility rule then applies.
 */
export function settleDeliveredCommission(d: AppData, order: DeliveryOrder, now: number) {
  if (order.status !== 'delivered' || !order.captainId || order.commissionFils === undefined) return;
  const key = commissionKey(order.id);
  if (d.walletTx.some((t) => t.idempotencyKey === key)) return;
  if (order.commissionFils === 0) return; // a 0% rate leaves nothing to post
  d.walletTx.unshift({
    id: uid('tx'),
    captainId: order.captainId,
    type: 'commission_debit',
    amount: -order.commissionFils,
    createdAt: now,
    actor: SYSTEM_ACTOR,
    orderId: order.id,
    commissionBp: order.commissionBp,
    idempotencyKey: key,
  });
}

/** Admin changes the global rate; audited with old and new values, applied to new acceptances only. */
export function updateCommissionRate(d: AppData, now: number, bp: number): Result {
  if (!isValidCommissionBp(bp)) return fail(COMMISSION_RATE_ERROR);
  const previousBp = d.settings.commissionBp;
  if (previousBp === bp) return fail('النسبة الجديدة مطابقة للنسبة الحالية');
  d.settings.commissionBp = bp;
  d.adminAudit.unshift({ id: uid('au'), kind: 'commission_rate', previousBp, nextBp: bp, actor: ADMIN_ACTOR, at: now });
  return done;
}
