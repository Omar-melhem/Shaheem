import type { Captain, LatLng } from './types';
import { haversineMeters } from './geo';

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
