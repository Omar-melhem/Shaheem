import type { ReactNode } from 'react';
import { CheckCircle2, Hourglass, PackageSearch, Store, Truck, UserCheck, Users } from 'lucide-react';
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

/** «مؤشرات التشغيل»: four live order counts (definitions in application/dashboard.ts). */
export function OperationalKpiSection({ kpis }: { kpis: OperationalKpis }) {
  return (
    <DashboardSection id="ops-kpis" title="مؤشرات التشغيل">
      <div className="grid grid-cols-2 gap-3 sm:gap-4 xl:grid-cols-4">
        <StatCard label="بانتظار التوزيع" value={kpis.queue} icon={<Hourglass className="h-5 w-5" />} tone={kpis.queue ? 'warning' : 'neutral'} hint="تحتاج إسناداً من الإدارة" />
        <StatCard label="معروضة على الكباتن" value={kpis.offered} icon={<PackageSearch className="h-5 w-5" />} tone="warning" hint="بث عام أو عرض خاص قائم" />
        <StatCard label="توصيلات نشطة" value={kpis.activeDeliveries} icon={<Truck className="h-5 w-5" />} tone="primary" hint="من القبول حتى التسليم" />
        <StatCard label="تم التسليم اليوم" value={kpis.deliveredToday} icon={<CheckCircle2 className="h-5 w-5" />} tone="secondary" hint="حسب يوم عمّان" />
      </div>
    </DashboardSection>
  );
}

/** «حسابات المنصة»: quieter account counts, three even columns. */
export function PlatformKpiSection({ kpis }: { kpis: PlatformKpis }) {
  return (
    <DashboardSection id="platform-kpis" title="حسابات المنصة">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 sm:gap-4">
        <div className="col-span-2 sm:col-span-1">
        <StatCard
          label="الكباتن المتاحون الآن"
          value={<>{kpis.availableNow} <span className="text-sm font-bold text-ink-muted">/ {kpis.activeCaptainAccounts}</span></>}
          icon={<UserCheck className="h-5 w-5" />}
          tone="secondary"
          hint="متاح من الحسابات المفعّلة"
        />
        </div>
        <StatCard label="إجمالي التجار" value={kpis.merchants} icon={<Store className="h-5 w-5" />} hint="كل حسابات التجار" />
        <StatCard label="إجمالي الكباتن" value={kpis.captains} icon={<Users className="h-5 w-5" />} hint="كل حسابات الكباتن" />
      </div>
    </DashboardSection>
  );
}
