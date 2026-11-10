import type { Captain } from './types';

export type LocationFreshness = 'live' | 'stale' | 'last_known' | 'demo' | 'none';

export const FRESHNESS_LABEL: Record<LocationFreshness, string> = {
  live: 'تتبع نشط (محاكاة)',
  stale: 'موقع متأخر — انقطع التحديث',
  last_known: 'آخر موقع معروف',
  demo: 'موقع تجريبي — غير متتبَّع',
  none: 'لا يتوفر موقع',
};

/**
 * GPS is tracked during an active delivery only (SRS §6.8). Outside a trip we
 * never claim a live position.
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
  return loc.source === 'demo_idle' ? 'demo' : 'last_known';
}
