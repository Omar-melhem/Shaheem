import type { ReactNode } from 'react';
import { CalendarClock, CheckCircle2, Hourglass, PackageSearch, Store, TriangleAlert, Truck, Users } from 'lucide-react';
import { ORDER_GROUP_LABEL } from '@/domain/orderStatus';
import type { OperationalKpis, PlatformKpis } from '@/application/dashboard';
import { StatCard } from '@/shared/components/ui';

/** A titled dashboard block; every section uses the same heading rhythm. */
export function DashboardSection({ id, title, children }: { id: string; title: string; children: ReactNode }) {
  return (
    <section aria-labelledby={id} className="min-w-0">
      <h2 id={id} className="mb-3 text-base font-extrabold text-ink">{title}</h2>
      {children}
    </section>
  );
}

/**
 * «مؤشرات التشغيل»: six live order counts (definitions in application/dashboard.ts). Group labels
 * come from ORDER_GROUP_LABEL so they read the same here and in the distribution center.
 */
export function OperationalKpiSection({ kpis }: { kpis: OperationalKpis }) {
  return (
    <DashboardSection id="ops-kpis" title="مؤشرات التشغيل">
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 sm:gap-4 xl:grid-cols-3">
        <StatCard label={ORDER_GROUP_LABEL.pending_dispatch} value={kpis.pendingDispatch} icon={<Hourglass className="h-5 w-5" />} tone={kpis.pendingDispatch ? 'warning' : 'neutral'} hint="لم تُعرض بعد على الكباتن" />
        <StatCard label={ORDER_GROUP_LABEL.needs_admin} value={kpis.needsAdmin} icon={<TriangleAlert className="h-5 w-5" />} tone={kpis.needsAdmin ? 'danger' : 'neutral'} hint="انتهت الجولات دون قبول" />
        <StatCard label={ORDER_GROUP_LABEL.offered} value={kpis.offered} icon={<PackageSearch className="h-5 w-5" />} tone="warning" hint="بث عام أو عرض خاص قائم" />
        <StatCard label={ORDER_GROUP_LABEL.active} value={kpis.activeDeliveries} icon={<Truck className="h-5 w-5" />} tone="primary" hint="من القبول حتى التسليم" />
        <StatCard label="تم التسليم اليوم" value={kpis.deliveredToday} icon={<CheckCircle2 className="h-5 w-5" />} tone="secondary" hint="حسب يوم عمّان" />
        <StatCard label="الطلبات المؤجلة اليوم" value={kpis.scheduledToday} icon={<CalendarClock className="h-5 w-5" />} tone="secondary" hint="موعد استلامها اليوم" />
      </div>
    </DashboardSection>
  );
}

/** «حسابات المنصة»: quieter account counts, two even columns. */
export function PlatformKpiSection({ kpis }: { kpis: PlatformKpis }) {
  return (
    <DashboardSection id="platform-kpis" title="حسابات المنصة">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 sm:gap-4">
        <StatCard label="إجمالي التجار" value={kpis.merchants} icon={<Store className="h-5 w-5" />} hint="كل حسابات التجار" />
        <StatCard label="إجمالي الكباتن" value={kpis.captains} icon={<Users className="h-5 w-5" />} hint="كل حسابات الكباتن" />
      </div>
    </DashboardSection>
  );
}
