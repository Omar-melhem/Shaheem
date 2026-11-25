import { Bike, LocateOff, MapPinned, Truck } from 'lucide-react';
import type { DeliveryOrder } from '@/domain/types';
import { LATE_DELIVERY_AFTER_MIN, isDeliveryLate } from '@/domain/orderStatus';
import { isPinnedOnLiveMap } from '@/domain/location';
import type { CaptainView } from '@/shared/hooks/application';
import { StatCard } from '@/shared/components/ui';

/**
 * Live-map counts from the same `presence` the pins use, so the numbers match the map:
 * pins shown, Available (recent report), delivering, and «GPS متأخر» = a delivering Captain whose
 * location stopped, or whose delivery status has not moved for LATE_DELIVERY_AFTER_MIN (demo
 * threshold). Offline and suspended Captains are not counted here.
 */
export function LiveMapStats({ views, orders, now }: { views: CaptainView[]; orders: DeliveryOrder[]; now: number }) {
  const pinned = views.filter((v) => isPinnedOnLiveMap(v.presence)).length;
  const available = views.filter((v) => v.presence === 'available').length;
  const delivering = views.filter((v) => v.presence === 'delivering' || v.presence === 'delivering_stale').length;
  const isLate = (v: CaptainView) => {
    const order = v.activeOrderId ? orders.find((o) => o.id === v.activeOrderId) : undefined;
    return !!order && isDeliveryLate(order, now);
  };
  const stale = views.filter((v) => v.presence === 'delivering_stale' || (v.presence === 'delivering' && isLate(v))).length;
  return (
    <div className="mb-4 grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
      <StatCard label="على الخريطة" value={pinned} icon={<MapPinned className="h-5 w-5" />} tone="secondary" hint="متاح بموقع محدَّث أو في توصيل" />
      <StatCard label="متاحون" value={available} icon={<Bike className="h-5 w-5" />} hint="آخر تحديث خلال 90 ثانية" />
      <StatCard label="في توصيل نشط" value={delivering} icon={<Truck className="h-5 w-5" />} tone="primary" hint="من القبول حتى التسليم" />
      <StatCard label="GPS متأخر" value={stale} icon={<LocateOff className="h-5 w-5" />} tone={stale ? 'danger' : 'neutral'} hint={`انقطع الموقع أو لا تحديث للحالة منذ ${LATE_DELIVERY_AFTER_MIN} د`} />
    </div>
  );
}
