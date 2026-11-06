import { formatJodInput, parseJodAmount } from './money';
import type { Money } from './types';

export const ORDER_VALUE_REQUIRED = 'قيمة الطلب مطلوبة';
export const ORDER_VALUE_INVALID = 'يرجى إدخال قيمة طلب صحيحة';
const ORDER_VALUE_PRECISION = 'قيمة الطلب تقبل ثلاث خانات عشرية كحد أقصى';
const ORDER_VALUE_AMBIGUOUS = 'الفاصلة هنا ملتبسة: اكتب 1.500 لدينار ونصف، أو 1500 لألف وخمسمئة دينار';

const ERRORS = {
  empty: ORDER_VALUE_REQUIRED,
  malformed: ORDER_VALUE_INVALID,
  precision: ORDER_VALUE_PRECISION,
  ambiguous: ORDER_VALUE_AMBIGUOUS,
};

export type OrderValueCheck = { ok: true; fils: Money; display: string } | { ok: false; error: string };

/** The order value rule (CR v1.3 §8): required and strictly positive, separate from the delivery fee. */
export function checkOrderValue(raw: string): OrderValueCheck {
  const parsed = parseJodAmount(raw);
  if (!parsed.ok) return { ok: false, error: ERRORS[parsed.reason] };
  if (parsed.fils <= 0) return { ok: false, error: ORDER_VALUE_INVALID };
  return { ok: true, fils: parsed.fils, display: formatJodInput(parsed.fils) };
}
