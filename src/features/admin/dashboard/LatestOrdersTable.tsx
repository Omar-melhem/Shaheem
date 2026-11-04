import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Ban, Eye, Inbox } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { DeliveryOrder } from '@/domain/types';
import { CANCELLABLE_STATUSES } from '@/domain/orderStatus';
import { formatMoney } from '@/domain/money';
import { Button, Card, CardHeader, EmptyState } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { formatDateTime, formatRelative } from '@/shared/lib/format';
import { OrderDetailDrawer } from '../OrderDetailDrawer';
import { CancelOrderDialog } from '../CancelOrderDialog';

const LATEST_COUNT = 8;
const HEADERS = ['رقم الطلب', 'التاجر', 'المنطقة', 'رسوم التوصيل', 'الحالة', 'وقت الإنشاء', 'آخر تحديث', 'الإجراءات'];

/** «أحدث الطلبات» with explicit headers and per-row actions (FU-1.2 §4). Reuses the order drawer and cancel dialog. */
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
        <div className="overflow-x-auto">
          <table className="w-full min-w-[900px] text-sm">
            <thead className="bg-cream text-xs text-ink-muted">
              <tr>
                {HEADERS.map((h) => (
                  <th key={h} scope="col" className="whitespace-nowrap px-4 py-3 text-start font-bold">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-cream-dark">
              {latest.map((o) => {
                const cancellable = CANCELLABLE_STATUSES.includes(o.status);
                return (
                  <tr key={o.id} className="align-middle">
                    <th scope="row" className="whitespace-nowrap px-4 py-3 text-start font-mono font-bold text-ink" dir="ltr">{o.reference}</th>
                    <td className="whitespace-nowrap px-4 py-3">{merchantName(o.merchantId)}</td>
                    <td className="px-4 py-3">{o.areaName}</td>
                    <td className="whitespace-nowrap px-4 py-3 font-bold">{formatMoney(o.deliveryPrice)}</td>
                    <td className="px-4 py-3"><OrderStatusBadge status={o.status} /></td>
                    <td className="whitespace-nowrap px-4 py-3 text-xs text-ink-soft">{formatDateTime(o.createdAt)}</td>
                    <td className="whitespace-nowrap px-4 py-3 text-xs text-ink-muted">{formatRelative(o.updatedAt, now)}</td>
                    <td className="px-4 py-3">
                      <div className="flex gap-1.5">
                        <Button size="sm" variant="outline" icon={<Eye className="h-3.5 w-3.5" />} onClick={() => setDetailId(o.id)} aria-label={`عرض تفاصيل ${o.reference}`}>
                          عرض التفاصيل
                        </Button>
                        <Button
                          size="sm"
                          variant="ghost"
                          icon={<Ban className="h-3.5 w-3.5" />}
                          disabled={!cancellable}
                          title={cancellable ? undefined : 'الإلغاء متاح قبل قبول الكابتن فقط'}
                          onClick={() => setCancelling(o)}
                          aria-label={`إلغاء الطلب ${o.reference}`}
                        >
                          إلغاء الطلب
                        </Button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
      <OrderDetailDrawer orderId={detailId} onClose={() => setDetailId(null)} />
      <CancelOrderDialog order={cancelling} onClose={() => setCancelling(null)} />
    </Card>
  );
}
