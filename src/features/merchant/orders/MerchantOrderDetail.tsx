import { useMemo } from 'react';
import { useAppStore } from '@/app/state';
import type { DeliveryOrder } from '@/domain/types';
import { formatMoney } from '@/domain/money';
import { formatAmmanDateTime } from '@/domain/time';
import { DetailRow, Drawer } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { OrderHistoryList } from '@/shared/components/OrderTimeline';
import { formatDateTime } from '@/shared/lib/format';

/**
 * Read-only order details for the Merchant. The history shows status changes only: internal notes
 * (offers withdrawn, which Captain declined, Admin remarks) stay with Admin.
 */
export function MerchantOrderDetail({ order, onClose }: { order: DeliveryOrder | null; onClose: () => void }) {
  const captain = useAppStore((s) => s.captains.find((c) => c.id === order?.captainId));
  const statusOnly = useMemo(
    () => (order ? { ...order, history: order.history.filter((h) => h.from !== h.to).map((h) => ({ ...h, note: undefined })) } : null),
    [order],
  );
  if (!order || !statusOnly) return null;
  const scheduled = order.requestType === 'scheduled';
  return (
    <Drawer open onClose={onClose} title={<span dir="ltr">{order.reference}</span>} subtitle={<OrderStatusBadge status={order.status} scheduled={scheduled} />}>
      <dl className="divide-y divide-cream-dark rounded-xl bg-white px-4">
        <DetailRow label="منطقة التوصيل">{order.areaName}</DetailRow>
        <DetailRow label="الوجهة">{order.destination.label}</DetailRow>
        <DetailRow label="رسوم التوصيل">{formatMoney(order.deliveryPrice)}</DetailRow>
        <DetailRow label="هاتف العميل">{order.customerPhone ? <span dir="ltr">{order.customerPhone}</span> : <span className="text-ink-muted">غير مضاف</span>}</DetailRow>
        <DetailRow label="نوع الطلب">{scheduled ? 'طلب مؤجل' : 'طلب فوري'}</DetailRow>
        {scheduled && order.scheduledPickupAt !== undefined && <DetailRow label="موعد الاستلام">{formatAmmanDateTime(order.scheduledPickupAt)}</DetailRow>}
        <DetailRow label="الكابتن">{captain ? captain.fullName : <span className="text-ink-muted">لم يُسند</span>}</DetailRow>
        <DetailRow label="وقت الطلب">{formatDateTime(order.createdAt)}</DetailRow>
        {order.deliveredAt !== undefined && <DetailRow label="وقت التسليم">{formatDateTime(order.deliveredAt)}</DetailRow>}
      </dl>
      <section aria-labelledby="merchant-order-history" className="rounded-xl bg-white p-4">
        <h3 id="merchant-order-history" className="mb-3 text-sm font-bold text-ink">مراحل الطلب</h3>
        <OrderHistoryList order={statusOnly} />
      </section>
    </Drawer>
  );
}
