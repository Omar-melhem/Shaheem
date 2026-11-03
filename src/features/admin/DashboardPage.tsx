import { Link } from 'react-router-dom';
import { Bike, CheckCircle2, Clock, Hourglass, PackageSearch, Send, SignalLow, Store, UserPlus, Users, Truck, AlertTriangle } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { useCaptainViews, useNow } from '@/application/hooks';
import { isActiveDelivery, isInQueue } from '@/domain/orderStatus';
import { formatMoney } from '@/domain/money';
import { Card, CardHeader, EmptyState, PageHeader, StatCard, SimTag } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { formatRelative } from '@/shared/lib/format';
import { BroadcastControl } from './BroadcastControl';

export function DashboardPage() {
  const now = useNow(5000);
  const orders = useAppStore((s) => s.orders);
  const merchants = useAppStore((s) => s.merchants);
  const alerts = useAppStore((s) => s.alerts);
  const captains = useCaptainViews(now);

  const startOfDay = new Date(now).setHours(0, 0, 0, 0);
  const queue = orders.filter((o) => isInQueue(o.status));
  const offered = orders.filter((o) => o.status === 'awaiting_captain' || o.status === 'offered_privately');
  const active = orders.filter((o) => isActiveDelivery(o.status));
  const deliveredToday = orders.filter((o) => o.status === 'delivered' && (o.deliveredAt ?? 0) >= startOfDay);
  const eligible = captains.filter((c) => c.eligibility.eligible);
  const available = captains.filter((c) => c.opStatus === 'available');
  const busy = captains.filter((c) => c.opStatus === 'busy');
  const stale = captains.filter((c) => c.freshness === 'stale');
  const merchantName = (id: string) => merchants.find((m) => m.id === id)?.businessName ?? '—';

  return (
    <>
      <PageHeader
        title="لوحة التحكم"
        description="نظرة تشغيلية فورية على التوزيع والتوصيلات والكباتن. الأرقام محسوبة من بيانات العرض التجريبية."
        actions={
          <>
            <Link to="/admin/merchants?new=1" className="inline-flex h-10 items-center gap-2 rounded-xl border border-cream-deep bg-white px-4 text-sm font-bold hover:bg-cream">
              <Store className="h-4 w-4" /> إضافة تاجر
            </Link>
            <Link to="/admin/captains?new=1" className="inline-flex h-10 items-center gap-2 rounded-xl border border-cream-deep bg-white px-4 text-sm font-bold hover:bg-cream">
              <UserPlus className="h-4 w-4" /> إضافة كابتن
            </Link>
            <Link to="/admin/dispatch" className="inline-flex h-10 items-center gap-2 rounded-xl bg-primary px-4 text-sm font-bold text-white hover:bg-primary-600">
              <Send className="h-4 w-4" /> مركز التوزيع
            </Link>
          </>
        }
      />

      <BroadcastControl />

      <div className="mt-6 grid grid-cols-2 gap-4 md:grid-cols-4">
        <StatCard label="بانتظار التوزيع" value={queue.length} icon={<Hourglass className="h-5 w-5" />} tone={queue.length ? 'warning' : 'neutral'} />
        <StatCard label="معروضة على الكباتن" value={offered.length} icon={<PackageSearch className="h-5 w-5" />} tone="warning" />
        <StatCard label="توصيلات نشطة" value={active.length} icon={<Truck className="h-5 w-5" />} tone="primary" />
        <StatCard label="سُلّمت اليوم" value={deliveredToday.length} icon={<CheckCircle2 className="h-5 w-5" />} tone="secondary" />
        <StatCard label="كباتن مؤهلون الآن" value={eligible.length} icon={<Bike className="h-5 w-5" />} tone="secondary" hint={`من ${available.length} متاح`} />
        <StatCard label="كباتن في توصيل" value={busy.length} icon={<Clock className="h-5 w-5" />} tone="primary" />
        <StatCard label="GPS متأخر أثناء توصيل" value={stale.length} icon={<SignalLow className="h-5 w-5" />} tone={stale.length ? 'danger' : 'neutral'} />
        <StatCard label="التجار / الكباتن" value={`${merchants.length} / ${captains.length}`} icon={<Users className="h-5 w-5" />} />
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-5">
        <Card className="xl:col-span-3">
          <CardHeader title="أحدث الطلبات" actions={<Link to="/admin/orders" className="text-sm font-bold text-primary hover:underline">كل الطلبات</Link>} />
          <ul className="divide-y divide-cream-dark">
            {orders.slice().sort((a, b) => b.updatedAt - a.updatedAt).slice(0, 8).map((o) => (
              <li key={o.id} className="flex flex-wrap items-center gap-3 px-5 py-3">
                <span className="font-mono text-sm font-bold text-ink" dir="ltr">{o.reference}</span>
                <span className="min-w-0 flex-1 truncate text-sm text-ink-soft">
                  {merchantName(o.merchantId)} ← {o.areaName}
                </span>
                <span className="text-sm font-bold">{formatMoney(o.deliveryPrice)}</span>
                <OrderStatusBadge status={o.status} />
                <span className="w-20 text-end text-xs text-ink-muted">{formatRelative(o.updatedAt, now)}</span>
              </li>
            ))}
          </ul>
        </Card>

        <Card className="xl:col-span-2">
          <CardHeader title="التنبيهات التشغيلية" icon={<AlertTriangle className="h-5 w-5" />} />
          {alerts.length === 0 ? (
            <EmptyState title="لا توجد تنبيهات" />
          ) : (
            <ul className="max-h-[420px] divide-y divide-cream-dark overflow-y-auto">
              {alerts.slice(0, 12).map((a) => (
                <li key={a.id} className="px-5 py-3">
                  <p className="text-sm text-ink">{a.message}</p>
                  <p className="text-xs text-ink-muted">{formatRelative(a.at, now)}</p>
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>

      <p className="mt-6 flex items-center gap-2 text-xs text-ink-muted">
        <SimTag /> المؤشرات التحليلية الإضافية (معدلات القبول، متوسط زمن الإسناد…) مقترحة وتنتظر اعتماد تعريفاتها.
      </p>
    </>
  );
}
