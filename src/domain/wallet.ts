import type { DeliveryOrder, ID, Money, WalletTransaction } from './types';
import { isActiveDelivery } from './orderStatus';

/**
 * Admin top-up cap (owner, 2026-11-25: «الحد الأقصى للشحن 5»). Read as **5.000 JOD per top-up
 * transaction**, not a maximum wallet balance — an assumption awaiting the owner's confirmation.
 */
export const MAX_TOPUP_FILS: Money = 5_000;
export const TOPUP_AMOUNT_ERROR = 'أدخل مبلغاً موجباً، مثل 5 أو 2.5';
export const TOPUP_LIMIT_ERROR = 'الحد الأقصى للشحن 5.000 د.أ في العملية الواحدة';

/** Why a top-up amount is refused, or null. */
export function topUpAmountError(amount: Money): string | null {
  if (!Number.isInteger(amount) || amount <= 0) return TOPUP_AMOUNT_ERROR;
  if (amount > MAX_TOPUP_FILS) return TOPUP_LIMIT_ERROR;
  return null;
}

/** One ledger entry per business operation, whatever is retried. */
export const rechargeKey = (operationId: string) => `recharge:${operationId}`;
export const commissionKey = (orderId: ID) => `commission:${orderId}`;

/** Ledger balance: the signed sum of every entry (credits minus commission debits). */
export function ledgerBalance(tx: WalletTransaction[], captainId: ID): Money {
  return tx.filter((t) => t.captainId === captainId).reduce((sum, t) => sum + t.amount, 0);
}

/**
 * Commission held on a Captain's accepted, not-yet-delivered orders. A hold is not revenue and
 * not a ledger entry: it is the locked snapshot on the order, and becomes the single debit on
 * delivery. Cancelling or never delivering releases it simply by the order leaving this set.
 */
export function heldCommission(orders: DeliveryOrder[], captainId: ID): Money {
  return orders
    .filter((o) => o.captainId === captainId && isActiveDelivery(o.status) && o.commissionFils !== undefined)
    .reduce((sum, o) => sum + (o.commissionFils ?? 0), 0);
}

/**
 * SHAHM's realised commission revenue: the finalised commission debits (as a positive amount).
 * Top-ups and holds are never revenue. Gross revenue, not profit after costs.
 */
export function realizedCommission(tx: WalletTransaction[], include: (t: WalletTransaction) => boolean = () => true): Money {
  return tx.filter((t) => t.type === 'commission_debit' && include(t)).reduce((sum, t) => sum - t.amount, 0);
}
