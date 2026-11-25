import { Satellite, SatelliteDish, WifiOff } from 'lucide-react';
import type { Captain } from '@/domain/types';
import { IDLE_REPORT_INTERVAL_SEC, type LocationFreshness } from '@/domain/location';
import { cn } from '@/shared/lib/cn';

/**
 * GPS status in the Captain header: every 60 s while Available with no delivery, every 30 s during a
 * delivery, nothing while unavailable (`domain/location.ts`).
 */
export function GpsChip({ captain, freshness, hasActive }: { captain: Captain; freshness: LocationFreshness; hasActive: boolean }) {
  if (!hasActive) {
    const idleReporting = captain.status === 'active' && captain.availability === 'available' && captain.gpsSignal === 'ok';
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-white/15 px-2 py-1 text-[11px] font-bold" title={idleReporting ? `يُرسل موقعك كل ${IDLE_REPORT_INTERVAL_SEC} ثانية ما دمت متاحاً` : 'لا يُرسل الموقع وأنت غير متاح'}>
        <Satellite className="h-3.5 w-3.5" /> {idleReporting ? `الموقع كل ${IDLE_REPORT_INTERVAL_SEC} ث` : 'التتبع متوقف'}
      </span>
    );
  }
  const lost = captain.gpsSignal === 'lost' || freshness === 'stale';
  return (
    <span className={cn('inline-flex items-center gap-1 rounded-full px-2 py-1 text-[11px] font-bold', lost ? 'bg-amber-400 text-ink' : 'bg-secondary-400 text-white')} role="status">
      {lost ? <WifiOff className="h-3.5 w-3.5" /> : <SatelliteDish className="h-3.5 w-3.5" />}
      {lost ? 'GPS منقطع' : 'تتبع نشط'}
    </span>
  );
}
