import { Bike, CheckCircle2, Hourglass, PackageSearch, SignalLow, Store, Truck, Users } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { useCaptainViews } from '@/application/hooks';
import { isActiveDelivery, isInQueue, isOffering } from '@/domain/orderStatus';
import { StatCard } from '@/shared/components/ui';

/**
 * «نظرة عامة»: eight KPI cards (FU-1.2 §3). The existing metric definitions are kept;
 * «كباتن في توصيل» is removed and the old combined Merchants / Captains card is split
 * into two separate account counts.
 */
export function OverviewSection({ now }: { now: number }) {
  const orders = useAppStore((s) => s.orders);
  const merchantCount = useAppStore((s) => s.merchants.length);
  const captains = useCaptainViews(now);

  const startOfDay = new Date(now).setHours(0, 0, 0, 0);
  const queue = orders.filter((o) => isInQueue(o.status)).length;
  const offered = orders.filter((o) => isOffering(o.status)).length;
  const active = orders.filter((o) => isActiveDelivery(o.status)).length;
  const deliveredToday = orders.filter((o) => o.status === 'delivered' && (o.deliveredAt ?? 0) >= startOfDay).length;
  const eligible = captains.filter((c) => c.eligibility.eligible).length;
  const available = captains.filter((c) => c.opStatus === 'available').length;
  const stale = captains.filter((c) => c.freshness === 'stale').length;

  return (
    <section aria-labelledby="overview-title" className="mt-6">
      <h2 id="overview-title" className="mb-3 text-lg font-extrabold text-ink">
        نظرة عامة
      </h2>
      <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
        <StatCard label="بانتظار التوزيع" value={queue} icon={<Hourglass className="h-5 w-5" />} tone={queue ? 'warning' : 'neutral'} />
        <StatCard label="معروضة على الكباتن" value={offered} icon={<PackageSearch className="h-5 w-5" />} tone="warning" />
        <StatCard label="توصيلات نشطة" value={active} icon={<Truck className="h-5 w-5" />} tone="primary" />
        <StatCard label="سُلّمت اليوم" value={deliveredToday} icon={<CheckCircle2 className="h-5 w-5" />} tone="secondary" />
        <StatCard label="كباتن مؤهلون الآن" value={eligible} icon={<Bike className="h-5 w-5" />} tone="secondary" hint={`من ${available} متاح`} />
        <StatCard label="GPS متأخر أثناء توصيل" value={stale} icon={<SignalLow className="h-5 w-5" />} tone={stale ? 'danger' : 'neutral'} />
        <StatCard label="إجمالي التجار" value={merchantCount} icon={<Store className="h-5 w-5" />} hint="حسابات التجار" />
        <StatCard label="إجمالي الكباتن" value={captains.length} icon={<Users className="h-5 w-5" />} hint="حسابات الكباتن" />
      </div>
    </section>
  );
}
