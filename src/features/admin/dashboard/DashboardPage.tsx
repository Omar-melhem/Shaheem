import { Link } from 'react-router-dom';
import { Send, Store, UserPlus } from 'lucide-react';
import { useNow } from '@/application/hooks';
import { PageHeader, SimTag } from '@/shared/components/ui';
import { BroadcastControl } from '../BroadcastControl';
import { OverviewSection } from './OverviewSection';
import { LatestOrdersTable } from './LatestOrdersTable';
import { OperationalAlerts } from './OperationalAlerts';

const LINK_OUTLINE = 'inline-flex h-10 items-center gap-2 rounded-xl border border-cream-deep bg-white px-4 text-sm font-bold hover:bg-cream';

/** Admin dashboard: composition only — overview cards, latest orders, then operational alerts. */
export function DashboardPage() {
  const now = useNow(5000);
  return (
    <>
      <PageHeader
        title="لوحة التحكم"
        description="نظرة تشغيلية فورية على التوزيع والتوصيلات والكباتن. الأرقام محسوبة من بيانات العرض التجريبية."
        actions={
          <>
            <Link to="/admin/merchants?new=1" className={LINK_OUTLINE}>
              <Store className="h-4 w-4" /> إضافة تاجر
            </Link>
            <Link to="/admin/captains?new=1" className={LINK_OUTLINE}>
              <UserPlus className="h-4 w-4" /> إضافة كابتن
            </Link>
            <Link to="/admin/dispatch" className="inline-flex h-10 items-center gap-2 rounded-xl bg-primary px-4 text-sm font-bold text-white hover:bg-primary-600">
              <Send className="h-4 w-4" /> مركز التوزيع
            </Link>
          </>
        }
      />

      <BroadcastControl />
      <OverviewSection now={now} />

      <div className="mt-6 space-y-6">
        <LatestOrdersTable now={now} />
        <OperationalAlerts now={now} />
      </div>

      <p className="mt-6 flex items-center gap-2 text-xs text-ink-muted">
        <SimTag /> المؤشرات التحليلية الإضافية (معدلات القبول، متوسط زمن الإسناد…) مقترحة وتنتظر اعتماد تعريفاتها.
      </p>
    </>
  );
}
