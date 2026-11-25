import type { Captain } from './types';

export type LocationFreshness = 'live' | 'reported' | 'stale' | 'last_known' | 'demo' | 'none';

export const FRESHNESS_LABEL: Record<LocationFreshness, string> = {
  live: 'تتبع نشط (محاكاة)',
  reported: 'موقع محدَّث — متاح (محاكاة)',
  stale: 'موقع متأخر — انقطع التحديث',
  last_known: 'آخر موقع معروف',
  demo: 'موقع تجريبي — غير متتبَّع',
  none: 'لا يتوفر موقع',
};

/**
 * Location reporting cadence (owner, 2026-11-25). The Captain app sends these reports; the Admin
 * web only reads them. Reporting interval ≠ freshness: a position is stale only after
 * `IDLE_STALE_AFTER_SEC` (historical 90 s), so one missed report does not hide a Captain.
 *  - Available, no active delivery: a report attempt every 60 s.
 *  - Active delivery: the existing 30 s target (unchanged by this request).
 *  - Offline, suspended or unavailable with no delivery: no tracking.
 * A future scheduled commitment without an active delivery counts as idle.
 */
export const IDLE_REPORT_INTERVAL_SEC = 60;
export const ACTIVE_REPORT_INTERVAL_SEC = 30;
export const IDLE_STALE_AFTER_SEC = 90;

export function locationReportIntervalSec(state: { accountActive: boolean; available: boolean; hasActiveDelivery: boolean }): number | null {
  if (state.hasActiveDelivery) return ACTIVE_REPORT_INTERVAL_SEC;
  if (state.accountActive && state.available) return IDLE_REPORT_INTERVAL_SEC;
  return null;
}

/**
 * GPS during an active delivery is `live` until it stops updating. Outside a trip, only an Available
 * Captain's recent periodic report (`idle_report`, within 90 s) is `reported`; anything older is a
 * last-known position and is never presented as current.
 */
export function locationFreshness(
  captain: Captain,
  now: number,
  staleAfterSec: number,
  activeOrderId: string | undefined,
): LocationFreshness {
  const loc = captain.lastLocation;
  if (!loc) return 'none';
  if (activeOrderId && loc.source === 'trip_simulated' && loc.activeOrderId === activeOrderId) {
    return now - loc.recordedAt > staleAfterSec * 1000 ? 'stale' : 'live';
  }
  if (activeOrderId) return 'stale';
  if (loc.source === 'idle_report') return now - loc.recordedAt <= IDLE_STALE_AFTER_SEC * 1000 ? 'reported' : 'last_known';
  return loc.source === 'demo_idle' ? 'demo' : 'last_known';
}

/**
 * Live map presence (owner, 2026-11-25): only Available Captains with a recent report, and
 * Captains on an active delivery with live GPS, are pins. A delivering Captain whose GPS stopped
 * is listed beside the map (`delivering_stale`), never pinned as if current. Offline, suspended
 * and not-yet-reported Captains are not shown at all, even if an old coordinate is stored.
 */
export type MapPresence = 'available' | 'delivering' | 'delivering_stale' | 'hidden';

export function liveMapPresence(state: { accountActive: boolean; available: boolean; hasActiveDelivery: boolean; freshness: LocationFreshness }): MapPresence {
  if (!state.accountActive) return 'hidden';
  if (state.hasActiveDelivery) return state.freshness === 'live' ? 'delivering' : 'delivering_stale';
  return state.available && state.freshness === 'reported' ? 'available' : 'hidden';
}

export const isPinnedOnLiveMap = (presence: MapPresence) => presence === 'available' || presence === 'delivering';
