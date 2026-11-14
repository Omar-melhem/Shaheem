import { useAppStore } from '@/app/state';
import { OP_STATUS_LABEL, type CaptainView } from '@/shared/hooks/application';
import { ORDER_STATUS_LABEL } from '@/domain/orderStatus';
import { Card, DetailRow, Drawer } from '@/shared/components/ui';
import { CaptainStatusBadge, FreshnessBadge, OrderStatusBadge } from '@/shared/components/StatusBadge';
import { DeliveryProgress } from '@/shared/components/OrderTimeline';
import { formatDateTime, formatRelative } from '@/shared/lib/format';


/** Captain information opened from the Live Map (FU-1.2 §6.2). Shows only what the system holds. */
export function CaptainDetailsPanel({ view, now, onClose }: { view: CaptainView | null; now: number; onClose: () => void }) {
  const order = useAppStore((s) => s.orders.find((o) => o.id === view?.activeOrderId));
  if (!view) return <Drawer open={false} onClose={onClose} title="">{null}</Drawer>;
  const { captain } = view;
  const loc = captain.lastLocation;

  return (
    <Drawer open onClose={onClose} title={captain.fullName} subtitle={<CaptainStatusBadge status={view.opStatus} />}>
      <Card className="px-4 py-2">
        <dl className="divide-y divide-cream-dark">
          <DetailRow label="رقم الكابتن"><span dir="ltr" className="font-mono text-xs">{captain.id}</span></DetailRow>
          <DetailRow label="حالة الحساب">{captain.status === 'active' ? 'مفعّل' : 'موقوف'}</DetailRow>
          <DetailRow label="التوفر">{OP_STATUS_LABEL[view.opStatus]}</DetailRow>
          <DetailRow label="الهاتف"><span dir="ltr">{captain.phone}</span></DetailRow>
        </dl>
      </Card>

      <Card className="space-y-3 p-4">
        <h3 className="text-sm font-bold">التوصيل الحالي</h3>
        {order ? (
          <>
            <div className="flex flex-wrap items-center gap-2 text-sm">
              <span className="font-mono font-bold" dir="ltr">{order.reference}</span>
              <OrderStatusBadge status={order.status} scheduled={order.requestType === 'scheduled'} />
            </div>
            <p className="text-sm text-ink-soft">المرحلة: <b>{ORDER_STATUS_LABEL[order.status]}</b> · المنطقة: {order.areaName}</p>
            <DeliveryProgress order={order} />
          </>
        ) : (
          <p className="text-sm text-ink-muted">لا يوجد توصيل نشط لهذا الكابتن.</p>
        )}
      </Card>

      <Card className="space-y-2 p-4">
        <h3 className="text-sm font-bold">الموقع</h3>
        <FreshnessBadge freshness={view.freshness} />
        {loc ? (
          <p className="text-xs text-ink-muted">
            آخر تحديث {formatRelative(loc.recordedAt, now)} ({formatDateTime(loc.recordedAt)})
          </p>
        ) : (
          <p className="text-xs text-ink-muted">لا يتوفر أي موقع لهذا الكابتن.</p>
        )}
        <p className="text-[11px] text-ink-muted">يُتتبع الموقع أثناء التوصيل النشط فقط. أي موقع آخر تجريبي أو آخر موقع معروف، ولا يُعرض كموقع مباشر.</p>
      </Card>
    </Drawer>
  );
}
