import { Bike, Radio, SignalLow, Truck } from 'lucide-react';
import type { CaptainView } from '@/application/hooks';
import { StatCard } from '@/shared/components/ui';

/**
 * Captain counts with explicit definitions: "online" = active account that is
 * available or on a delivery; "delivering" = has an active delivery. Online does
 * not mean GPS-tracked — only active deliveries are tracked.
 */
export function LiveMapStats({ views }: { views: CaptainView[] }) {
  const busy = views.filter((v) => v.opStatus === 'busy').length;
  const available = views.filter((v) => v.opStatus === 'available').length;
  const stale = views.filter((v) => v.freshness === 'stale').length;
  return (
    <div className="mb-4 grid grid-cols-2 gap-3 lg:grid-cols-4">
      <StatCard label="كباتن متصلون" value={busy + available} icon={<Radio className="h-5 w-5" />} tone="secondary" hint="متاح أو في توصيل" />
      <StatCard label="في توصيل نشط" value={busy} icon={<Truck className="h-5 w-5" />} tone="primary" hint="يُتتبع موقعهم" />
      <StatCard label="متاحون بلا توصيل" value={available} icon={<Bike className="h-5 w-5" />} hint="موقع غير متتبَّع" />
      <StatCard label="GPS متأخر" value={stale} icon={<SignalLow className="h-5 w-5" />} tone={stale ? 'danger' : 'neutral'} hint="أثناء توصيل نشط" />
    </div>
  );
}
