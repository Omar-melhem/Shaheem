import type { Money } from './types';

/**
 * SHAHM commission = a percentage of the order's delivery-fee snapshot (CR v1.4 §3), never of
 * goods value («مجموع الطلب») and never a flat amount. The rate is held in basis points
 * (20% = 2000) so no float is involved. Rounding rule (proposed, needs owner approval): round
 * half up to the nearest fils.
 *
 * Lifecycle (owner, 2026-11-25): the rate and amount are locked on the order when a Captain
 * accepts (that reserved amount is a hold, not revenue); the one debit is posted when the order
 * is delivered. Admin may change the global rate; it applies to new acceptances only.
 */
export const DEFAULT_COMMISSION_BP = 2000;
export const MAX_COMMISSION_BP = 10_000;

/** The range the code has always accepted (0–100%). A narrower approved range is still open. */
export const isValidCommissionBp = (bp: number) => Number.isInteger(bp) && bp >= 0 && bp <= MAX_COMMISSION_BP;

/** fee (fils) × bp / 10000, rounded half up to a whole fils. Integer arithmetic only. */
export function commissionFils(deliveryFee: Money, bp: number): Money {
  if (!Number.isInteger(deliveryFee) || deliveryFee < 0 || !isValidCommissionBp(bp)) throw new RangeError('invalid fee or rate');
  return Math.floor((deliveryFee * bp + 5_000) / 10_000);
}

/** "20%" or "12.5%". */
export const formatPercentBp = (bp: number) => `${(bp / 100).toLocaleString('en', { maximumFractionDigits: 2 })}%`;

/** Editable text for a rate: "20" or "12.5". */
export const formatPercentInput = (bp: number) => (bp / 100).toLocaleString('en', { maximumFractionDigits: 2, useGrouping: false });

export const COMMISSION_RATE_ERROR = 'أدخل نسبة بين 0 و100، بخانتين عشريتين كحد أقصى (مثل 20 أو 12.5)';

/**
 * Typed percentage → basis points without a float: "20" → 2000, "12.5" → 1250, "٢٠" → 2000.
 * null for anything else (empty, negative, exponent, over 100%, more than two decimals).
 */
export function parsePercentToBp(raw: string): number | null {
  const text = raw
    .trim()
    .replace(/[٠-٩]/g, (d) => String('٠١٢٣٤٥٦٧٨٩'.indexOf(d)))
    .replace(/[٫,]/g, '.')
    .replace(/%$/, '')
    .trim();
  const match = /^(\d{1,3})(?:\.(\d{1,2}))?$/.exec(text);
  if (!match) return null;
  const bp = Number(match[1]) * 100 + Number((match[2] ?? '').padEnd(2, '0'));
  return isValidCommissionBp(bp) ? bp : null;
}
