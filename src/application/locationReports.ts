import { IDLE_REPORT_INTERVAL_SEC, locationReportIntervalSec } from '@/domain/location';
import type { AppData } from './data';
import { captainActiveOrder } from './captainQueries';

/**
 * DEMO STAND-IN for the Captain app: an Available Captain with no active delivery reports their
 * position every 60 s (owner, 2026-11-25). The position does not move (no movement is invented);
 * a lost signal sends nothing, so the location goes stale exactly as it would in the field.
 * Offline or suspended Captains are not tracked. Active-delivery GPS is the trip simulation in
 * the store's tick. In production these reports come from the Captain app through the backend.
 */
export function reportIdleLocations(d: AppData, now: number) {
  for (const captain of d.captains) {
    const loc = captain.lastLocation;
    if (!loc || captain.gpsSignal === 'lost' || captainActiveOrder(d, captain.id)) continue;
    const interval = locationReportIntervalSec({ accountActive: captain.status === 'active', available: captain.availability === 'available', hasActiveDelivery: false });
    if (interval !== IDLE_REPORT_INTERVAL_SEC) continue;
    const due = loc.source !== 'idle_report' || now - loc.recordedAt >= interval * 1000;
    if (due) captain.lastLocation = { position: loc.position, recordedAt: now, source: 'idle_report' };
  }
}
