import { useMemo } from 'react';
import { Link, Navigate } from 'react-router-dom';
import { History, Truck } from 'lucide-react';
import { useSession } from '@/app/session';
import { useAppStore } from '@/app/state';
import { MERCHANT_RECENT_PREVIEW, merchantOrderOverview } from '@/application/dashboard';
import { Card, CardHeader, EmptyState } from '@/shared/components/ui';
import { RequestCaptainPanel } from './request-captain/RequestCaptainPanel';
import { ActiveOrderItem, HistoryItem } from './orders/MerchantOrderItems';

/**
 * Merchant Portal — one main screen (SRS §5.1): the request form first, then active deliveries,
 * then the latest three finished orders with a link to the full history. Only this Merchant's
 * data is read (isolation is enforced server-side in production — SRS §5.8).
 */
export function MerchantPortal() {
  const merchantId = useSession((s) => s.session?.id);
  const merchant = useAppStore((s) => s.merchants.find((m) => m.id === merchantId));
  const allOrders = useAppStore((s) => s.orders);
  const { active, history } = useMemo(() => merchantOrderOverview(allOrders, merchantId), [allOrders, merchantId]);
  if (!merchant) return <Navigate to="/login" replace />;
  const recent = history.slice(0, MERCHANT_RECENT_PREVIEW);

  return (
    <>
      <h1 className="sr-only">بوابة التاجر — {merchant.businessName}</h1>

      {/* Two columns only when the space beside the sidebar allows; the form always comes first. */}
      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.15fr)_minmax(0,1fr)] xl:items-start">
        <div className="min-w-0">
          <RequestCaptainPanel merchant={merchant} />
        </div>

        <div className="min-w-0 space-y-6">
          <Card>
            <CardHeader title={`التوصيلات النشطة (${active.length})`} icon={<Truck className="h-5 w-5" />} />
            {active.length === 0 ? (
              <EmptyState compact title="لا توجد طلبات نشطة حالياً. عند طلب كابتن تظهر حالته هنا وتتحدث تلقائياً." />
            ) : (
              <ul className="max-h-[560px] divide-y divide-cream-dark overflow-y-auto">
                {active.map((o) => <ActiveOrderItem key={o.id} order={o} />)}
              </ul>
            )}
          </Card>

          <Card>
            <CardHeader
              title="آخر الطلبات"
              icon={<History className="h-5 w-5" />}
              actions={history.length > 0 && <Link to="/merchant/orders" className="text-sm font-bold text-primary hover:underline">عرض كل الطلبات</Link>}
            />
            {recent.length === 0 ? (
              <EmptyState compact title="لا توجد طلبات سابقة. الطلبات المُسلّمة والملغاة تظهر هنا." />
            ) : (
              <ul className="divide-y divide-cream-dark">
                {recent.map((o) => <HistoryItem key={o.id} order={o} />)}
              </ul>
            )}
          </Card>
        </div>
      </div>
    </>
  );
}
