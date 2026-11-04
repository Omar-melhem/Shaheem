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
export const NO_CANDIDATE_REASON = 'لا يوجد كابتن مؤهل متبقٍ';

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
