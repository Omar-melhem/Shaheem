import { Bike, Radio, SignalLow, Truck } from 'lucide-react';
import type { DeliveryOrder } from '@/domain/types';
import { LATE_DELIVERY_AFTER_MIN, isDeliveryLate } from '@/domain/orderStatus';
import type { CaptainView } from '@/shared/hooks/application';
import { StatCard } from '@/shared/components/ui';

/**
 * Captain counts with explicit definitions: "online" = active account that is
 * available or on a delivery; "delivering" = has an active delivery. Online does
 * not mean GPS-tracked — only active deliveries are tracked. «GPS متأخر» counts Captains on an
 * active delivery whose location stopped updating, or whose delivery status has not moved for
 * LATE_DELIVERY_AFTER_MIN (demo threshold), so a stuck order is flagged even with simulated GPS.
 */
export function LiveMapStats({ views, orders, now }: { views: CaptainView[]; orders: DeliveryOrder[]; now: number }) {
  const busy = views.filter((v) => v.opStatus === 'busy').length;
  const available = views.filter((v) => v.opStatus === 'available').length;
  const isLate = (v: CaptainView) => {
    const order = v.activeOrderId ? orders.find((o) => o.id === v.activeOrderId) : undefined;
    return !!order && isDeliveryLate(order, now);
  };
  const stale = views.filter((v) => v.freshness === 'stale' || isLate(v)).length;
  return (
    <div className="mb-4 grid grid-cols-1 sm:grid-cols-2 gap-3 lg:grid-cols-4">
      <StatCard label="كباتن متصلون" value={busy + available} icon={<Radio className="h-5 w-5" />} tone="secondary" hint="متاح أو في توصيل" />
      <StatCard label="في توصيل نشط" value={busy} icon={<Truck className="h-5 w-5" />} tone="primary" hint="يُتتبع موقعهم" />
      <StatCard label="متاحون بلا توصيل" value={available} icon={<Bike className="h-5 w-5" />} hint="موقع غير متتبَّع" />
      <StatCard label="GPS متأخر" value={stale} icon={<SignalLow className="h-5 w-5" />} tone={stale ? 'danger' : 'neutral'} hint={`انقطع الموقع أو لا تحديث للحالة منذ ${LATE_DELIVERY_AFTER_MIN} د`} />
    </div>
  );
}
