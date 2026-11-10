import { useState } from 'react';
import { Marker, Polyline } from 'react-leaflet';
import { ExternalLink, MapPin, Navigation, Phone, Store, WifiOff, PackageCheck } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { Captain, DeliveryOrder } from '@/domain/types';
import type { LocationFreshness } from '@/domain/location';
import { CAPTAIN_NEXT_ACTION_LABEL } from '@/domain/orderStatus';
import { formatMoney } from '@/domain/money';
import { formatDistance, haversineMeters } from '@/domain/geo';
import { Button, ConfirmDialog, EmptyState } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { DeliveryProgress } from '@/shared/components/OrderTimeline';
import { BaseMap, FitBounds } from '@/shared/components/map/BaseMap';
import { captainIcon, destinationIcon, merchantIcon } from '@/shared/components/map/markers';
import { reportResult } from '@/shared/components/toast';
import { formatRelative } from '@/shared/lib/format';
import { NO_EXACT_LOCATION, isAreaOnly } from '@/domain/destination';

const mapsLink = (lat: number, lng: number) => `https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}`;
/** Customer location is a text description (no GPS), so directions use a text search. */
const mapsSearch = (text: string) => `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(text)}`;

/** Active delivery workflow — Captain confirms each stage and the delivery (SRS §6.7, §6.11). */
export function ActiveDeliveryTab({ captain, order, freshness, now }: { captain: Captain; order?: DeliveryOrder; freshness: LocationFreshness; now: number }) {
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === order?.merchantId));
  const advanceDelivery = useAppStore((s) => s.advanceDelivery);
  const [confirmDeliver, setConfirmDeliver] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  if (!order || !merchant) {
    return <EmptyState icon={<Navigation className="h-6 w-6" />} title="لا يوجد توصيل نشط" description="عند قبول عرض سيظهر هنا مسار التوصيل وخطواته." />;
  }

  const toPickup = order.status === 'accepted' || order.status === 'heading_to_pickup';
  const dest = order.destination.position;
  const areaOnly = isAreaOnly(order.destination);
  const target = toPickup ? order.pickup.position : dest;
  const loc = captain.lastLocation?.position;
  const nextLabel = CAPTAIN_NEXT_ACTION_LABEL[order.status];
  const lost = captain.gpsSignal === 'lost' || freshness === 'stale';

  const advance = () => {
    if (submitting) return;
    setSubmitting(true);
    const result = advanceDelivery(order.id, captain.id);
    setSubmitting(false);
    reportResult(result, result.ok && result.value === 'delivered' ? 'تم تأكيد التسليم — أحسنت!' : 'تم تحديث حالة التوصيل');
  };

  return (
    <div className="space-y-3 p-4">
      {lost && (
        <div className="flex items-start gap-2 rounded-xl border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900" role="alert">
          <WifiOff className="mt-0.5 h-4 w-4 shrink-0" />
          <div>
            <p className="font-bold">انقطع تحديث الموقع</p>
            <p className="text-xs">تحقق من تفعيل GPS وصلاحية الموقع. آخر تحديث {captain.lastLocation ? formatRelative(captain.lastLocation.recordedAt, now) : '—'}.</p>
          </div>
        </div>
      )}

      <div className="flex items-center justify-between">
        <span className="font-mono font-bold" dir="ltr">{order.reference}</span>
        <OrderStatusBadge status={order.status} scheduled={order.requestType === 'scheduled'} />
      </div>
      <div className="rounded-2xl bg-white p-3 shadow-card">
        <DeliveryProgress order={order} />
      </div>

      <BaseMap className="h-44" label="خريطة التوصيل">
        <FitBounds points={[order.pickup.position, ...(dest ? [dest] : []), ...(loc ? [loc] : [])]} fitKey={`${order.id}-${order.status}`} />
        <Marker position={[order.pickup.position.lat, order.pickup.position.lng]} icon={merchantIcon()} />
        {dest && <Marker position={[dest.lat, dest.lng]} icon={destinationIcon()} />}
        {loc && <Marker position={[loc.lat, loc.lng]} icon={captainIcon('busy', freshness)} zIndexOffset={500} />}
        {loc && target && <Polyline positions={[[loc.lat, loc.lng], [target!.lat, target!.lng]]} pathOptions={{ color: '#8C2335', dashArray: '5 8', weight: 2 }} />}
      </BaseMap>
      {loc && target && (
        <p className="text-center text-[11px] text-ink-muted">
          ≈ {formatDistance(haversineMeters(loc, target))} إلى {toPickup ? 'التاجر' : order.destination.approximate ? 'مركز منطقة العميل (تقريبي)' : 'موقع العميل'} · خط مستقيم · موقع محاكى
        </p>
      )}

      <section className={`space-y-2 rounded-2xl p-4 shadow-card ${toPickup ? 'bg-white ring-2 ring-primary-200' : 'bg-white'}`}>
        <p className="flex items-center gap-2 text-xs font-bold text-ink-muted"><Store className="h-4 w-4" /> الاستلام</p>
        <p className="font-bold">{merchant.businessName}</p>
        <p className="text-sm text-ink-muted">{merchant.address}</p>
        <div className="flex gap-2">
          <a href={`tel:${merchant.phone}`} className="inline-flex items-center gap-1 rounded-lg bg-cream px-3 py-1.5 text-xs font-bold"><Phone className="h-3.5 w-3.5" /> اتصال بالتاجر</a>
          <a href={mapsLink(order.pickup.position.lat, order.pickup.position.lng)} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 rounded-lg bg-cream px-3 py-1.5 text-xs font-bold"><ExternalLink className="h-3.5 w-3.5" /> الاتجاهات</a>
        </div>
      </section>

      <section className={`space-y-2 rounded-2xl p-4 shadow-card ${!toPickup ? 'bg-white ring-2 ring-primary-200' : 'bg-white'}`}>
        <p className="flex items-center gap-2 text-xs font-bold text-ink-muted"><MapPin className="h-4 w-4" /> التسليم</p>
        <p className="text-sm font-bold text-primary">منطقة {order.areaName}</p>
        <p className="font-bold">{order.destination.label}</p>
        {areaOnly && <p className="text-sm font-medium text-amber-800">{NO_EXACT_LOCATION}. الوجهة معروفة على مستوى المنطقة فقط.</p>}
        {order.destination.note && <p className="text-sm text-ink-soft">ملاحظة: {order.destination.note}</p>}
        {order.deliveryInstructions && <p className="text-sm text-ink-soft">تعليمات: {order.deliveryInstructions}</p>}
        {order.customerName && <p className="text-sm">العميل: {order.customerName}</p>}
        <div className="flex gap-2">
          {order.customerPhone && <a href={`tel:${order.customerPhone}`} className="inline-flex items-center gap-1 rounded-lg bg-cream px-3 py-1.5 text-xs font-bold"><Phone className="h-3.5 w-3.5" /> اتصال بالعميل</a>}
          <a href={order.destination.position && !order.destination.approximate ? mapsLink(order.destination.position.lat, order.destination.position.lng) : mapsSearch(`${order.destination.label}، ${order.destination.address}`)} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 rounded-lg bg-cream px-3 py-1.5 text-xs font-bold"><ExternalLink className="h-3.5 w-3.5" /> {areaOnly ? 'البحث عن المنطقة' : 'الاتجاهات'}</a>
        </div>
      </section>

      <div className="flex items-center justify-between rounded-2xl bg-white px-4 py-3 shadow-card">
        <span className="text-sm text-ink-muted">سعر التوصيل</span>
        <span className="text-lg font-extrabold text-secondary">{formatMoney(order.deliveryPrice)}</span>
      </div>

      {nextLabel && (
        <div className="sticky bottom-0 -mx-4 bg-gradient-to-t from-cream via-cream to-transparent px-4 pb-1 pt-4">
          <Button
            size="lg"
            className="w-full"
            variant={order.status === 'on_the_way' ? 'secondary' : 'primary'}
            icon={order.status === 'on_the_way' ? <PackageCheck className="h-5 w-5" /> : <Navigation className="h-5 w-5" />}
            loading={submitting}
            onClick={() => (order.status === 'on_the_way' ? setConfirmDeliver(true) : advance())}
          >
            {nextLabel}
          </Button>
        </div>
      )}

      <ConfirmDialog
        open={confirmDeliver}
        onClose={() => setConfirmDeliver(false)}
        onConfirm={advance}
        title="تأكيد تسليم الطلب؟"
        description={`تأكيد أنك سلّمت الطلب ${order.reference} إلى العميل. لا يلزم رمز تحقق أو توقيع أو صورة في النسخة الحالية.`}
        confirmLabel="تم التسليم"
        variant="secondary"
      />
    </div>
  );
}
