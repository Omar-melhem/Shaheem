import { useMemo } from 'react';
import { Link } from 'react-router-dom';
import { Send, Store, UserPlus } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { useCaptainViews, useNow } from '@/application/hooks';
import { availabilitySummary, operationalAlerts, operationalKpis, orderActivity, platformKpis, type CaptainSnapshot } from '@/application/dashboard';
import { PageHeader, SimTag } from '@/shared/components/ui';
import { BroadcastControl } from '../BroadcastControl';
import { DashboardSection, OperationalKpiSection, PlatformKpiSection } from './OverviewSection';
import { OrderActivityChart } from './OrderActivityChart';
import { LatestOrdersTable } from './LatestOrdersTable';
import { CaptainAvailabilityCard } from './CaptainAvailabilityCard';
import { OperationalAlerts } from './OperationalAlerts';

const ACTION = 'inline-flex h-10 items-center gap-2 rounded-xl border border-cream-deep bg-white px-4 text-sm font-bold hover:bg-cream focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300';

/**
 * «نظرة عامة»: composition only. Every number comes from application/dashboard.ts over the shared
 * store, one snapshot per render: KPIs → accounts → quick actions → activity → latest orders →
 * availability and alerts.
 */
export function DashboardPage() {
  const now = useNow(5000);
  const orders = useAppStore((s) => s.orders);
  const merchantCount = useAppStore((s) => s.merchants.length);
  const publicBroadcast = useAppStore((s) => s.settings.publicBroadcast);
  const views = useCaptainViews(now);

  const overview = useMemo(() => {
    const captains: CaptainSnapshot[] = views.map((v) => ({ opStatus: v.opStatus, eligible: v.eligibility.eligible, freshness: v.freshness }));
    const input = { orders, merchantCount, captains, publicBroadcast };
    return {
      ops: operationalKpis(orders, now),
      platform: platformKpis(input),
      availability: availabilitySummary(captains),
      activity: orderActivity(orders, now),
      alerts: operationalAlerts(input),
    };
  }, [orders, merchantCount, publicBroadcast, views, now]);

  return (
    <div className="min-w-0 space-y-8">
      <PageHeader title="نظرة عامة" description="ملخص العمليات وحالة التوصيل. الأرقام محسوبة من بيانات العرض التجريبية." />

      <OperationalKpiSection kpis={overview.ops} />
      <PlatformKpiSection kpis={overview.platform} />

      <DashboardSection id="quick-actions" title="إجراءات سريعة">
        <div className="mb-4 flex flex-wrap gap-2">
          <Link to="/admin/merchants?new=1" className={ACTION}><Store className="h-4 w-4" aria-hidden /> إضافة تاجر</Link>
          <Link to="/admin/captains?new=1" className={ACTION}><UserPlus className="h-4 w-4" aria-hidden /> إضافة كابتن</Link>
          <Link to="/admin/dispatch" className={ACTION}><Send className="h-4 w-4" aria-hidden /> توزيع يدوي</Link>
        </div>
        <BroadcastControl />
      </DashboardSection>

      <OrderActivityChart days={overview.activity} />
      <LatestOrdersTable now={now} />

      <div className="grid min-w-0 gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,2fr)]">
        <CaptainAvailabilityCard summary={overview.availability} />
        <OperationalAlerts alerts={overview.alerts} now={now} />
      </div>

      <p className="flex items-center gap-2 text-xs text-ink-muted">
        <SimTag /> المؤشرات التحليلية الإضافية (معدلات القبول، متوسط زمن الإسناد…) مقترحة وتنتظر اعتماد تعريفاتها.
      </p>
    </div>
  );
}
