import { useMemo } from 'react';
import { Link } from 'react-router-dom';
import { Send, Store, UserPlus } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { useNow } from '@/shared/hooks/application';
import { operationalKpis, platformKpis } from '@/application/dashboard';
import { PageHeader } from '@/shared/components/ui';
import { OperationalKpiSection, PlatformKpiSection } from './OverviewSection';
import { LatestOrdersTable } from './LatestOrdersTable';

const LINK_OUTLINE = 'inline-flex h-10 items-center gap-2 rounded-xl border border-cream-deep bg-white px-4 text-sm font-bold hover:bg-cream focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300';

/**
 * «نظرة عامة»: composition only. Quick actions sit in the page header; public broadcasting is
 * switched from the header pill beside the notifications. Every number comes from
 * application/dashboard.ts over the shared store: KPIs → accounts → latest orders.
 */
export function DashboardPage() {
  const now = useNow(5000);
  const orders = useAppStore((s) => s.orders);
  const merchantCount = useAppStore((s) => s.merchants.length);
  const captainCount = useAppStore((s) => s.captains.length);

  const overview = useMemo(
    () => ({ ops: operationalKpis(orders, now), platform: platformKpis({ merchantCount, captainCount }) }),
    [orders, merchantCount, captainCount, now],
  );

  return (
    <div className="min-w-0 space-y-8">
      <PageHeader
        title="نظرة عامة"
        description="ملخص العمليات وحالة التوصيل. الأرقام محسوبة من بيانات العرض التجريبية."
        actions={
          <>
            <Link to="/admin/merchants?new=1" className={LINK_OUTLINE}>
              <Store className="h-4 w-4" aria-hidden /> إضافة تاجر
            </Link>
            <Link to="/admin/captains?new=1" className={LINK_OUTLINE}>
              <UserPlus className="h-4 w-4" aria-hidden /> إضافة كابتن
            </Link>
            <Link to="/admin/dispatch" className="inline-flex h-10 items-center gap-2 rounded-xl bg-primary px-4 text-sm font-bold text-white hover:bg-primary-600 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300">
              <Send className="h-4 w-4" aria-hidden /> توزيع يدوي
            </Link>
          </>
        }
      />

      <OperationalKpiSection kpis={overview.ops} />
      <PlatformKpiSection kpis={overview.platform} />
      <LatestOrdersTable now={now} />
    </div>
  );
}
