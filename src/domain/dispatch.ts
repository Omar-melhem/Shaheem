import type { Captain, LatLng } from './types';
import { haversineMeters } from './geo';

/**
 * Public dispatch rounds (Product Owner, FU-1.2 §5): each round waits up to 60 s
 * for an acceptance; at most three rounds in total, then the order returns to the
 * Admin queue. Which Captains each round targets is still open (FU-1.2 §14.3) —
 * the existing demo offer policy (O-005) is kept.
 */
export const DISPATCH_ROUND_SEC = 60;
export const MAX_DISPATCH_ROUNDS = 3;
export const ROUNDS_EXHAUSTED_REASON = `لم يقبل أي كابتن بعد ${MAX_DISPATCH_ROUNDS} محاولات`;
/** Only when no Captain passes the shared eligibility check at that moment. */
export const NO_CANDIDATE_REASON = 'لا يوجد كابتن مؤهل متبقٍ';
/** Eligible Captains exist, but every one of them was already offered this cycle and none accepted. */
export const ALL_OFFERED_REASON = 'عُرض الطلب على كل الكباتن المؤهلين ولم يقبله أحد';

/** The reason ending automatic rounds, chosen from the same eligibility count the assign dialog uses. */
export const roundsEndedReason = (eligibleNow: number) => (eligibleNow === 0 ? NO_CANDIDATE_REASON : ALL_OFFERED_REASON);

/**
 * Queue reason as shown to Admin. A stored «no eligible Captain» reason is a snapshot; if Captains
 * have become eligible since, say so instead of contradicting the assign dialog.
 */
export function describeQueueReason(reason: string | undefined, eligibleNow: number): string | undefined {
  if (reason === NO_CANDIDATE_REASON && eligibleNow > 0) return `لم يتوفر كابتن مؤهل وقت التوزيع — يتوفر الآن ${eligibleNow} للإسناد الخاص`;
  return reason;
}

/**
 * Scheduled orders never enter public broadcast or the automatic round loop, even after
 * their time arrives (CR v1.4 §6.2). Every automatic path must check this.
 */
export const isAutoDispatchEligible = (order: { requestType?: 'immediate' | 'scheduled' }) => order.requestType !== 'scheduled';

export interface RankedCaptain {
  captain: Captain;
  distanceMeters: number;
}

/**
 * Nearest-to-Merchant ranking (SRS §8.1, §8.3). Uses straight-line distance as a
 * demo assumption — the distance method is open (O-004).
 */
export function rankByProximity(captains: Captain[], pickup: LatLng): RankedCaptain[] {
  return captains
    .filter((c) => c.lastLocation)
    .map((captain) => ({ captain, distanceMeters: haversineMeters(captain.lastLocation!.position, pickup) }))
    .sort((a, b) => a.distanceMeters - b.distanceMeters);
}
