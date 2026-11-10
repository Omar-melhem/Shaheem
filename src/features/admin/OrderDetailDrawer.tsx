import { Marker, Polyline, Popup } from 'react-leaflet';
import { NO_EXACT_LOCATION, isAreaOnly } from '@/domain/destination';
import { useAppStore } from '@/application/store';
import { useNow } from '@/application/hooks';
import { formatMoney } from '@/domain/money';
import { formatAmmanDateTime } from '@/domain/time';
import { formatDistance } from '@/domain/geo';
import { isActiveDelivery } from '@/domain/orderStatus';
import { MAX_DISPATCH_ROUNDS } from '@/domain/dispatch';
import { locationFreshness } from '@/domain/location';
import { Badge, Card, DetailRow, Drawer } from '@/shared/components/ui';
import { FreshnessBadge, OrderStatusBadge } from '@/shared/components/StatusBadge';
import { DeliveryProgress, OrderHistoryList } from '@/shared/components/OrderTimeline';
import { BaseMap, FitBounds } from '@/shared/components/map/BaseMap';
import { captainIcon, destinationIcon, merchantIcon } from '@/shared/components/map/markers';
import { formatDateTime, formatRelative } from '@/shared/lib/format';
import { OrderActions } from './OrderActions';

const OFFER_LABEL = { pending: 'بانتظار الرد', accepted: 'قَبِل', rejected: 'رفض', expired: 'انتهت المهلة', withdrawn: 'سُحب' } as const;

export function OrderDetailDrawer({ orderId, onClose }: { orderId: string | null; onClose: () => void }) {
  const now = useNow(2000);
  const order = useAppStore((s) => s.orders.find((o) => o.id === orderId));
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === order?.merchantId));
  const captain = useAppStore((s) => s.captains.find((c) => c.id === order?.captainId));
  const offers = useAppStore((s) => s.offers.filter((o) => o.orderId === orderId));
  const captains = useAppStore((s) => s.captains);
  const staleAfter = useAppStore((s) => s.demo.staleAfterSec);

  if (!order) return <Drawer open={false} onClose={onClose} title="">{null}</Drawer>;

  const active = isActiveDelivery(order.status);
  const freshness = captain ? locationFreshness(captain, now, staleAfter, active ? order.id : undefined) : 'none';
  const dest = order.destination.position;
  const points = [order.pickup.position, ...(dest ? [dest] : []), ...(active && captain?.lastLocation ? [captain.lastLocation.position] : [])];

  return (
    <Drawer
      open={!!orderId}
      onClose={onClose}
      title={<span dir="ltr">{order.reference}</span>}
      subtitle={
        <div className="flex flex-wrap items-center gap-2">
          <OrderStatusBadge status={order.status} scheduled={order.requestType === 'scheduled'} />
          {order.dispatchMode && <Badge tone="info">{order.dispatchMode === 'private' ? 'إسناد خاص' : 'بث عام'}</Badge>}
        </div>
      }
      footer={<OrderActions order={order} size="md" />}
    >
      {(active || order.status === 'delivered') && (
        <Card className="p-4">
          <DeliveryProgress order={order} />
        </Card>
      )}

      <BaseMap className="h-56" label="خريطة الطلب">
        <FitBounds points={points} fitKey={order.id} />
        <Marker position={[order.pickup.position.lat, order.pickup.position.lng]} icon={merchantIcon()} title="موقع الاستلام">
          <Popup>استلام: {merchant?.businessName}</Popup>
        </Marker>
        {dest && (
          <Marker position={[dest.lat, dest.lng]} icon={destinationIcon()} title="موقع العميل">
            <Popup>{order.areaName} — {order.destination.approximate ? 'موقع تقريبي (مركز المنطقة)' : order.destination.label}</Popup>
          </Marker>
        )}
        {active && captain?.lastLocation && (
          <Marker position={[captain.lastLocation.position.lat, captain.lastLocation.position.lng]} icon={captainIcon('busy', freshness)} title={captain.fullName}>
            <Popup>{captain.fullName}</Popup>
          </Marker>
        )}
        {dest && <Polyline positions={[[order.pickup.position.lat, order.pickup.position.lng], [dest.lat, dest.lng]]} pathOptions={{ color: '#8C2335', dashArray: '6 8', weight: 2 }} />}
      </BaseMap>

      <Card className="px-4 py-2">
        <dl className="divide-y divide-cream-dark">
          {order.queueReason && (order.status === 'dispatch_expired' || order.status === 'pending_dispatch') && (
            <DetailRow label="سبب العودة للطابور"><span className="font-bold text-red-800">{order.queueReason}</span></DetailRow>
          )}
          {order.requestType === 'scheduled' && order.scheduledPickupAt !== undefined && (
            <DetailRow label="طلب مؤجل — الاستلام">{formatAmmanDateTime(order.scheduledPickupAt)}</DetailRow>
          )}
          <DetailRow label="التاجر">{merchant?.businessName}</DetailRow>
          <DetailRow label="نقطة الاستلام">{order.pickup.address}</DetailRow>
          <DetailRow label="منطقة العميل">{order.areaName}</DetailRow>
          <DetailRow label="وصف العنوان">
            {order.destination.label}
            {isAreaOnly(order.destination) && <span className="block text-xs text-amber-800">{NO_EXACT_LOCATION}</span>}
            {order.destination.note && <span className="block text-xs text-ink-soft">ملاحظة: {order.destination.note}</span>}
          </DetailRow>
          {order.deliveryInstructions && <DetailRow label="تعليمات التوصيل">{order.deliveryInstructions}</DetailRow>}
          <DetailRow label="رسوم التوصيل (مقفلة)">
            {formatMoney(order.deliveryPrice)}
            <span className="block text-xs text-ink-muted">حُفظت {formatDateTime(order.pricingSnapshotAt)}</span>
          </DetailRow>
          <DetailRow label="هاتف العميل">{order.customerPhone ? <span dir="ltr">{order.customerPhone}</span> : <span className="text-ink-muted">غير مُدخل</span>}</DetailRow>
          <DetailRow label="قيمة الطلب">{order.mealValue !== undefined ? formatMoney(order.mealValue) : <span className="text-ink-muted">غير مُدخلة</span>}</DetailRow>
          <DetailRow label="الكابتن">
            {captain ? (
              <>
                {captain.fullName}
                {active && (
                  <span className="mt-1 flex flex-wrap justify-end gap-1">
                    <FreshnessBadge freshness={freshness} />
                    {captain.lastLocation && <span className="text-xs text-ink-muted">آخر تحديث {formatRelative(captain.lastLocation.recordedAt, now)}</span>}
                  </span>
                )}
              </>
            ) : (
              <span className="text-ink-muted">غير مسند</span>
            )}
          </DetailRow>
          <DetailRow label="أُنشئ">{formatDateTime(order.createdAt)}</DetailRow>
        </dl>
      </Card>

      {offers.length > 0 && (
        <Card className="p-4">
          <h3 className="mb-2 text-sm font-bold">محاولات التوزيع</h3>
          <ul className="space-y-1.5 text-sm">
            {offers.map((o) => (
              <li key={o.id} className="flex flex-wrap items-center gap-2">
                <span className="text-xs text-ink-muted">{o.attempt ? `جولة ${o.attempt} من ${MAX_DISPATCH_ROUNDS}` : `دورة ${o.round}`}</span>
                <span className="flex-1 font-medium">{captains.find((c) => c.id === o.captainId)?.fullName}</span>
                {o.distanceMeters !== undefined && <span className="text-xs text-ink-muted">{formatDistance(o.distanceMeters)}</span>}
                <Badge tone={o.mode === 'private' ? 'info' : 'neutral'}>{o.mode === 'private' ? 'خاص' : 'عام'}</Badge>
                <Badge tone={o.status === 'accepted' ? 'success' : o.status === 'pending' ? 'warning' : o.status === 'rejected' ? 'danger' : 'neutral'}>{OFFER_LABEL[o.status]}</Badge>
              </li>
            ))}
          </ul>
        </Card>
      )}

      <Card className="p-4">
        <h3 className="mb-3 text-sm font-bold">سجل الحالة</h3>
        <OrderHistoryList order={order} />
      </Card>
    </Drawer>
  );
}
