import { useMemo, useState } from 'react';
import { Navigate } from 'react-router-dom';
import { History } from 'lucide-react';
import { useSession } from '@/app/session';
import { useAppStore } from '@/app/state';
import { merchantOrderOverview } from '@/application/dashboard';
import { Card, CardHeader, EmptyState, Tabs } from '@/shared/components/ui';
import { HistoryItem } from './MerchantOrderItems';

type Filter = 'all' | 'delivered' | 'cancelled';

/** The Merchant's full order history (delivered and cancelled), filterable by outcome. */
export function MerchantOrdersPage() {
  const merchantId = useSession((s) => s.session?.id);
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === merchantId));
  const allOrders = useAppStore((s) => s.orders);
  const [filter, setFilter] = useState<Filter>('all');
  const { history } = useMemo(() => merchantOrderOverview(allOrders, merchantId), [allOrders, merchantId]);
  if (!merchant) return <Navigate to="/login" replace />;
  const shown = history.filter((o) => filter === 'all' || o.status === filter);

  return (
    <div className="mx-auto max-w-4xl">
      <h1 className="sr-only">سجل الطلبات — {merchant.businessName}</h1>
        <Card>
          <CardHeader
            title={`سجل الطلبات (${shown.length})`}
            icon={<History className="h-5 w-5" />}
            actions={
              <Tabs
                value={filter}
                onChange={setFilter}
                items={[
                  { value: 'all', label: 'الكل' },
                  { value: 'delivered', label: 'مُسلّمة' },
                  { value: 'cancelled', label: 'ملغاة' },
                ]}
              />
            }
          />
          {shown.length === 0 ? (
            <EmptyState compact title="لا توجد طلبات مطابقة. الطلبات الجارية تظهر في صفحة «طلب كابتن»." />
          ) : (
            <ul className="divide-y divide-cream-dark">
              {shown.map((o) => <HistoryItem key={o.id} order={o} />)}
            </ul>
          )}
        </Card>
    </div>
  );
}
