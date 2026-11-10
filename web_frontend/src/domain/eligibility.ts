import type { Captain, Money } from './types';
import { formatMoney } from './money';

export type IneligibilityReason = 'inactive_account' | 'offline' | 'busy' | 'insufficient_wallet' | 'no_location';

export const INELIGIBILITY_LABEL: Record<IneligibilityReason, string> = {
  inactive_account: 'الحساب غير مفعّل',
  offline: 'غير متاح حالياً',
  busy: 'لديه توصيل نشط',
  insufficient_wallet: 'رصيد المحفظة غير كافٍ',
  no_location: 'لا يتوفر موقع لترتيب القرب',
};

export interface EligibilityContext {
  hasActiveDelivery: boolean;
  balance: Money;
  /** Demo wallet threshold — the real amount is open (SRS O-020). */
  walletThreshold: Money;
}

export interface Eligibility {
  eligible: boolean;
  reasons: IneligibilityReason[];
}

/**
 * Candidate eligibility (SRS §8.2). One active delivery at a time is a demo
 * assumption (O-009). Balance must be > 0 and ≥ threshold (SRS §10.1).
 */
export function evaluateEligibility(captain: Captain, ctx: EligibilityContext): Eligibility {
  const reasons: IneligibilityReason[] = [];
  if (captain.status !== 'active') reasons.push('inactive_account');
  if (captain.availability !== 'available') reasons.push('offline');
  if (ctx.hasActiveDelivery) reasons.push('busy');
  if (ctx.balance <= 0 || ctx.balance < ctx.walletThreshold) reasons.push('insufficient_wallet');
  if (!captain.lastLocation) reasons.push('no_location');
  return { eligible: reasons.length === 0, reasons };
}

export function describeReasons(reasons: IneligibilityReason[], threshold?: Money): string {
  return reasons
    .map((r) =>
      r === 'insufficient_wallet' && threshold !== undefined
        ? `${INELIGIBILITY_LABEL[r]} (الحد التجريبي ${formatMoney(threshold)})`
        : INELIGIBILITY_LABEL[r],
    )
    .join('، ');
}
