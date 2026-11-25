import type { Money } from './types';
import { parseJodAmount } from './money';

/**
 * «مجموع الطلب» (owner, 2026-11-25): the optional goods/basket total of the customer's order.
 * Blank means absent, never 0.000. Information only — the delivery fee, SHAHM's commission and
 * revenue never read it. The upper bound only guards against typos and overflow (99,999.999 JOD).
 */
export const MAX_ORDER_TOTAL_FILS: Money = 99_999_999;
export const ORDER_TOTAL_ERROR = 'أدخل مجموع الطلب بالدينار، مثل 12.500، أو اتركه فارغاً';
export const ORDER_TOTAL_PRECISION_ERROR = 'مجموع الطلب: ثلاث خانات عشرية كحد أقصى';
export const ORDER_TOTAL_TOO_LARGE = 'مجموع الطلب أكبر من المسموح — تأكد من الرقم';

export const isValidOrderTotal = (value: Money | undefined) =>
  value === undefined || (Number.isInteger(value) && value >= 0 && value <= MAX_ORDER_TOTAL_FILS);

/** Typed text → fils (or undefined when blank), with an Arabic error when it cannot be used. */
export function parseOrderTotal(raw: string): { ok: true; fils: Money | undefined } | { ok: false; error: string } {
  if (!raw.trim()) return { ok: true, fils: undefined };
  const parsed = parseJodAmount(raw);
  if (!parsed.ok) return { ok: false, error: parsed.reason === 'precision' ? ORDER_TOTAL_PRECISION_ERROR : ORDER_TOTAL_ERROR };
  if (parsed.fils > MAX_ORDER_TOTAL_FILS) return { ok: false, error: ORDER_TOTAL_TOO_LARGE };
  return { ok: true, fils: parsed.fils };
}
