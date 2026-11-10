import { useMemo, useState } from 'react';
import { Navigate } from 'react-router-dom';
import { Bike, History, Phone, Truck } from 'lucide-react';
import { useSession } from '@/application/session';
import { useAppStore } from '@/application/store';
import { useNow } from '@/application/hooks';
import type { DeliveryOrder } from '@/domain/types';
import { FINAL_STATUSES, isActiveDelivery } from '@/domain/orderStatus';
import { formatMoney } from '@/domain/money';
import { formatAmmanDateTime } from '@/domain/time';
import { Card, CardHeader, EmptyState, Tabs } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { DeliveryProgress } from '@/shared/components/OrderTimeline';
import { formatDateTime, formatRelative } from '@/shared/lib/format';
import { RequestCaptainPanel } from './request-captain/RequestCaptainPanel';
import { MerchantHeader } from './MerchantHeader';

/**
 * Merchant Portal — a single main screen (SRS §5.1): request action, active
 * orders and history. Only this Merchant's data is read (isolation is enforced
 * server-side in production — SRS §5.8).
 */
export function MerchantPortal() {
  const merchantId = useSession((s) => s.session?.id);
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === merchantId));
  const allOrders = useAppStore((s) => s.orders);
  const [historyFilter, setHistoryFilter] = useState<'all' | 'delivered' | 'cancelled'>('all');

  const orders = useMemo(() => allOrders.filter((o) => o.merchantId === merchantId).sort((a, b) => b.createdAt - a.createdAt), [allOrders, merchantId]);
  if (!merchant) return <Navigate to="/login" replace />;

  const current = orders.filter((o) => !FINAL_STATUSES.includes(o.status));
  const history = orders.filter((o) => FINAL_STATUSES.includes(o.status)).filter((o) => historyFilter === 'all' || o.status === historyFilter);

  return (
    <div className="min-h-screen">
      <MerchantHeader merchant={merchant} page="home" />

      <main className="mx-auto grid max-w-6xl gap-6 px-4 py-6 lg:grid-cols-[minmax(0,1.1fr)_minmax(0,1fr)]">
        <div className="space-y-4">
          <RequestCaptainPanel merchant={merchant} />
        </div>

        <div className="space-y-6">
          <Card>
            <CardHeader title={`الطلبات الحالية (${current.length})`} icon={<Truck className="h-5 w-5" />} />
            {current.length === 0 ? (
              <EmptyState icon={<Bike className="h-6 w-6" />} title="لا توجد طلبات نشطة" description="عند طلب كابتن ستظهر حالة الطلب هنا وتتحدث تلقائياً." />
            ) : (
              <ul className="divide-y divide-cream-dark">
                {current.map((o) => (
                  <ActiveOrderItem key={o.id} order={o} />
                ))}
              </ul>
            )}
          </Card>

          <Card>
            <CardHeader
              title="سجل الطلبات"
              icon={<History className="h-5 w-5" />}
              actions={
                <Tabs
                  value={historyFilter}
                  onChange={setHistoryFilter}
                  items={[
                    { value: 'all', label: 'الكل' },
                    { value: 'delivered', label: 'مُسلّمة' },
                    { value: 'cancelled', label: 'ملغاة' },
                  ]}
                />
              }
            />
            {history.length === 0 ? (
              <EmptyState title="لا توجد طلبات سابقة" />
            ) : (
              <ul className="max-h-[420px] divide-y divide-cream-dark overflow-y-auto">
                {history.map((o) => (
                  <HistoryItem key={o.id} order={o} />
                ))}
              </ul>
            )}
          </Card>
        </div>
      </main>
    </div>
  );
}

function ActiveOrderItem({ order }: { order: DeliveryOrder }) {
  const now = useNow(5000);
  const captain = useAppStore((s) => s.captains.find((c) => c.id === order.captainId));
  const active = isActiveDelivery(order.status);
  return (
    <li className="space-y-3 px-5 py-4">
      <div className="flex flex-wrap items-center gap-2">
        <span className="font-mono font-bold" dir="ltr">{order.reference}</span>
        <OrderStatusBadge status={order.status} scheduled={order.requestType === 'scheduled'} />
        <span className="ms-auto text-xs text-ink-muted">آخر تحديث {formatRelative(order.updatedAt, now)}</span>
      </div>
      <p className="text-sm text-ink-soft">
        إلى <b>{order.destination.label}</b> ({order.areaName}) · {formatMoney(order.deliveryPrice)}
      </p>
      {order.requestType === 'scheduled' && order.scheduledPickupAt !== undefined && (
        <p className="rounded-lg bg-sand-light/30 px-3 py-1.5 text-xs">طلب مؤجل · موعد الاستلام <b>{formatAmmanDateTime(order.scheduledPickupAt)}</b></p>
      )}
      {active && <DeliveryProgress order={order} />}
      {captain && active ? (
        <div className="flex items-center gap-3 rounded-xl bg-cream px-3 py-2">
          <Bike className="h-5 w-5 text-primary" />
          <span className="flex-1 text-sm">
            الكابتن <b>{captain.fullName}</b>
          </span>
          <a href={`tel:${captain.phone}`} className="inline-flex items-center gap-1 text-sm font-bold text-primary hover:underline">
            <Phone className="h-4 w-4" /> اتصال
          </a>
        </div>
      ) : (
        <p className="text-xs text-ink-muted">
          {order.requestType === 'scheduled'
            ? order.status === 'offered_privately'
              ? 'عُرض الطلب على كابتن وبانتظار قبوله.'
              : 'بانتظار تنسيق الإدارة لكابتن في الموعد المطلوب. لم يُسند كابتن بعد.'
            : order.status === 'awaiting_captain' || order.status === 'offered_privately'
            ? 'جارٍ البحث عن كابتن قريب…'
            : order.status === 'dispatch_expired'
              ? 'لم يقبل أي كابتن بعد — فريق شهم يتابع الطلب.'
              : 'الطلب في انتظار التوزيع من فريق شهم.'}
        </p>
      )}
    </li>
  );
}

function HistoryItem({ order }: { order: DeliveryOrder }) {
  const captain = useAppStore((s) => s.captains.find((c) => c.id === order.captainId));
  return (
    <li className="flex flex-wrap items-center gap-x-3 gap-y-1 px-5 py-3 text-sm">
      <span className="font-mono font-bold" dir="ltr">{order.reference}</span>
      <span className="min-w-0 flex-1 truncate text-ink-soft">
        {order.destination.label} · {order.areaName}
      </span>
      <span className="font-bold">{formatMoney(order.deliveryPrice)}</span>
      <OrderStatusBadge status={order.status} scheduled={order.requestType === 'scheduled'} />
      <span className="w-full text-xs text-ink-muted">
        {formatDateTime(order.createdAt)}
        {order.requestType === 'scheduled' && order.scheduledPickupAt !== undefined && ` · مؤجل لـ ${formatAmmanDateTime(order.scheduledPickupAt)}`}
        {captain && ` · ${captain.fullName}`}
      </span>
    </li>
  );
}
