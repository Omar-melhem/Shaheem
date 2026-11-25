import type { Captain, LatLng } from './types';
import { formatDistance, haversineMeters } from './geo';

/**
 * Public dispatch rounds (owner, 2026-11-25), each 60 s, measured from the **Merchant pickup**:
 *  1. the 3 nearest eligible Captains within 5 km;
 *  2. the next 3 nearest within 10 km who have not been offered this order;
 *  3. every remaining eligible Captain within 10 km.
 * No acceptance after round 3 → Admin queue, never a 4th automatic round.
 *
 * Proposed readings awaiting owner confirmation: «3 إلى 5 كيلو» = three Captains within 5 km (not
 * a 3–5 km band); round 2 targets three; rounds 2 and 3 also last 60 s. Change them here only.
 */
export interface DispatchRoundPolicy {
  radiusMeters: number;
  /** null = everyone left within the radius. */
  maxCaptains: number | null;
}

export const DISPATCH_ROUNDS: readonly DispatchRoundPolicy[] = [
  { radiusMeters: 5_000, maxCaptains: 3 },
  { radiusMeters: 10_000, maxCaptains: 3 },
  { radiusMeters: 10_000, maxCaptains: null },
];

export const DISPATCH_ROUND_SEC = 60;
export const MAX_DISPATCH_ROUNDS = DISPATCH_ROUNDS.length;
export const MAX_DISPATCH_RADIUS_M = Math.max(...DISPATCH_ROUNDS.map((r) => r.radiusMeters));

export const roundPolicy = (attempt: number): DispatchRoundPolicy | undefined => DISPATCH_ROUNDS[attempt - 1];

/** "أقرب 3 كباتن ضمن 5 كم" / "كل الكباتن المتبقين ضمن 10 كم". */
export function describeRound(policy: DispatchRoundPolicy): string {
  const radius = formatDistance(policy.radiusMeters);
  return policy.maxCaptains === null ? `كل الكباتن المؤهلين المتبقين ضمن ${radius}` : `أقرب ${policy.maxCaptains} كباتن مؤهلين ضمن ${radius}`;
}

export const ROUNDS_EXHAUSTED_REASON = `لم يقبل أي كابتن بعد ${MAX_DISPATCH_ROUNDS} محاولات`;
/** Only when no Captain passes the shared eligibility check at that moment. */
export const NO_CANDIDATE_REASON = 'لا يوجد كابتن مؤهل متبقٍ';
/** Eligible Captains in range exist, but every one of them was already offered this cycle and none accepted. */
export const ALL_OFFERED_REASON = 'عُرض الطلب على كل الكباتن المؤهلين ضمن نطاق التوزيع ولم يقبله أحد';
/** Eligible Captains exist, but none is within the largest round radius of the Merchant. */
export const OUT_OF_RANGE_REASON = `لا يوجد كابتن مؤهل ضمن ${formatDistance(MAX_DISPATCH_RADIUS_M)} من التاجر`;

/**
 * The reason ending automatic rounds, from the same eligibility count the assign dialog uses and
 * how many of those Captains are within the largest radius (defaults to all of them).
 */
export const roundsEndedReason = (eligibleNow: number, eligibleInRange: number = eligibleNow) =>
  eligibleNow === 0 ? NO_CANDIDATE_REASON : eligibleInRange === 0 ? OUT_OF_RANGE_REASON : ALL_OFFERED_REASON;

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
 * Nearest-to-Merchant ranking (SRS §8.1, §8.3) by great-circle (haversine) distance from the
 * pickup — never the customer destination. Road distance is open (O-004).
 */
export function rankByProximity(captains: Captain[], pickup: LatLng): RankedCaptain[] {
  return captains
    .filter((c) => c.lastLocation)
    .map((captain) => ({ captain, distanceMeters: haversineMeters(captain.lastLocation!.position, pickup) }))
    .sort((a, b) => a.distanceMeters - b.distanceMeters);
}

/**
 * Who receives a round: the nearest Captains within its radius (inclusive), not yet offered, up to
 * its size. `ranked` must already be eligible-only and sorted by distance.
 */
export function selectRoundCandidates(ranked: RankedCaptain[], policy: DispatchRoundPolicy, alreadyOffered: ReadonlySet<string>): RankedCaptain[] {
  const inRange = ranked.filter((r) => r.distanceMeters <= policy.radiusMeters && !alreadyOffered.has(r.captain.id));
  return policy.maxCaptains === null ? inRange : inRange.slice(0, policy.maxCaptains);
}
