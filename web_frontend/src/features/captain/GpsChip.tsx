import { Satellite, SatelliteDish, WifiOff } from 'lucide-react';
import type { Captain } from '@/domain/types';
import type { LocationFreshness } from '@/domain/location';
import { cn } from '@/shared/lib/cn';

/** GPS status in the Captain header. Tracking runs during an active delivery only. */
export function GpsChip({ captain, freshness, hasActive }: { captain: Captain; freshness: LocationFreshness; hasActive: boolean }) {
  if (!hasActive) {
    return (
      <span className="inline-flex items-center gap-1 rounded-full bg-white/15 px-2 py-1 text-[11px] font-bold" title="لا يتم تتبع الموقع خارج التوصيل النشط">
        <Satellite className="h-3.5 w-3.5" /> التتبع متوقف
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
