import type { Money } from './types';

/**
 * SHAHM commission = a percentage of the order's delivery-fee snapshot (CR v1.4 §3), never
 * of goods value and never a flat amount. The rate is held in basis points (20% = 2000) so
 * no float is involved. Rounding rule (proposed, needs owner approval): round half up to
 * the nearest fils.
 *
 * Display and calculation only: no debit, hold or editable setting exists in this
 * repository, because wallets need a transactional backend
 * (docs/wallet-commission-backend-contract.md).
 */
export const COMMISSION_BP_PROPOSED = 2000;
export const MAX_COMMISSION_BP = 10_000;

export const isValidCommissionBp = (bp: number) => Number.isInteger(bp) && bp >= 0 && bp <= MAX_COMMISSION_BP;

/** fee (fils) × bp / 10000, rounded half up to a whole fils. Integer arithmetic only. */
export function commissionFils(deliveryFee: Money, bp: number): Money {
  if (!Number.isInteger(deliveryFee) || deliveryFee < 0 || !isValidCommissionBp(bp)) throw new RangeError('invalid fee or rate');
  return Math.floor((deliveryFee * bp + 5_000) / 10_000);
}

/** "20%" or "12.5%". */
export const formatPercentBp = (bp: number) => `${(bp / 100).toLocaleString('en', { maximumFractionDigits: 2 })}%`;
