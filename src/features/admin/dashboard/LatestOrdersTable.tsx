import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Ban, Eye, Inbox } from 'lucide-react';
import { useAppStore } from '@/app/state';
import type { DeliveryOrder } from '@/domain/types';
import { CANCELLABLE_STATUSES } from '@/domain/orderStatus';
import { formatMoney } from '@/domain/money';
import { Card, CardHeader, DataTable, EmptyState, IconAction, RowActions } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { formatDateTime, formatRelative } from '@/shared/lib/format';
import { OrderDetailDrawer } from '../OrderDetailDrawer';
import { CancelOrderDialog } from '../CancelOrderDialog';

const LATEST_COUNT = 8;
const HEADERS = ['رقم الطلب', 'التاجر', 'المنطقة', 'رسوم التوصيل', 'الحالة', 'وقت الإنشاء', 'آخر تحديث'];
const LEGEND = [
  { icon: <Eye />, label: 'عرض تفاصيل الطلب' },
  { icon: <Ban />, label: 'إلغاء الطلب (قبل قبول الكابتن فقط، مع تأكيد)' },
];

/** «أحدث الطلبات» with explicit headers and per-row icon actions (FU-1.2 §4). Reuses the order drawer and cancel dialog. */
export function LatestOrdersTable({ now }: { now: number }) {
  const orders = useAppStore((s) => s.orders);
  const merchants = useAppStore((s) => s.merchants);
  const [detailId, setDetailId] = useState<string | null>(null);
  const [cancelling, setCancelling] = useState<DeliveryOrder | null>(null);

  const latest = orders.slice().sort((a, b) => b.updatedAt - a.updatedAt).slice(0, LATEST_COUNT);
  const merchantName = (id: string) => merchants.find((m) => m.id === id)?.businessName ?? '—';

  return (
    <Card>
      <CardHeader title="أحدث الطلبات" actions={<Link to="/admin/orders" className="text-sm font-bold text-primary hover:underline">كل الطلبات</Link>} />
      {latest.length === 0 ? (
        <EmptyState icon={<Inbox className="h-6 w-6" />} title="لا توجد طلبات بعد" />
      ) : (
        <DataTable headers={HEADERS} actionsLegend={LEGEND} minWidth={900}>
          {latest.map((o) => {
            const cancellable = CANCELLABLE_STATUSES.includes(o.status);
            return (
              <tr key={o.id} className="align-middle">
                <th scope="row" className="whitespace-nowrap px-4 py-3 text-start font-mono font-bold text-ink" dir="ltr">{o.reference}</th>
                <td className="whitespace-nowrap px-4 py-3">{merchantName(o.merchantId)}</td>
                <td className="px-4 py-3">{o.areaName}</td>
                <td className="whitespace-nowrap px-4 py-3 font-bold">{formatMoney(o.deliveryPrice)}</td>
                <td className="px-4 py-3"><OrderStatusBadge status={o.status} scheduled={o.requestType === 'scheduled'} /></td>
                <td className="whitespace-nowrap px-4 py-3 text-xs text-ink-soft">{formatDateTime(o.createdAt)}</td>
                <td className="whitespace-nowrap px-4 py-3 text-xs text-ink-muted">{formatRelative(o.updatedAt, now)}</td>
                <RowActions>
                  <IconAction icon={<Eye />} label={`عرض تفاصيل ${o.reference}`} onClick={() => setDetailId(o.id)} />
                  <IconAction
                    icon={<Ban />}
                    label={cancellable ? `إلغاء الطلب ${o.reference}` : 'الإلغاء متاح قبل قبول الكابتن فقط'}
                    tone="danger"
                    disabled={!cancellable}
                    onClick={() => setCancelling(o)}
                  />
                </RowActions>
              </tr>
            );
          })}
        </DataTable>
      )}
      <OrderDetailDrawer orderId={detailId} onClose={() => setDetailId(null)} />
      <CancelOrderDialog order={cancelling} onClose={() => setCancelling(null)} />
    </Card>
  );
}
