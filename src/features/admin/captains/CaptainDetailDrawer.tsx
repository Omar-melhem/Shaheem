import { useMemo, useState } from 'react';
import { Pencil, Wallet } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { useCaptainViews, useNow, type CaptainView } from '@/shared/hooks/application';
import type { Captain } from '@/domain/types';
import { formatMoney } from '@/domain/money';
import { describeReasons } from '@/domain/eligibility';
import { Button, Card, DetailRow, Drawer, Toggle } from '@/shared/components/ui';
import { CaptainStatusBadge, FreshnessBadge, OrderStatusBadge } from '@/shared/components/StatusBadge';
import { formatDate, formatDateTime, formatRelative } from '@/shared/lib/format';
import { CaptainTripHistory } from './CaptainTripHistory';
import { CaptainRatingForm } from './CaptainRatingForm';
import { CaptainStatusDialog } from './CaptainStatusDialog';

/** Captain details: account, wallet, eligibility, 3-day trips, rating and deliveries. */
export function CaptainDetailDrawer({
  captainId,
  onClose,
  onEdit,
  onRecharge,
}: {
  captainId: string | null;
  onClose: () => void;
  onEdit: (c: Captain) => void;
  onRecharge: (v: CaptainView) => void;
}) {
  const now = useNow(2000);
  const views = useCaptainViews(now);
  const orders = useAppStore((s) => s.orders);
  const threshold = useAppStore((s) => s.demo.walletThreshold);
  const [confirming, setConfirming] = useState(false);

  const view = views.find((v) => v.captain.id === captainId);
  const captainOrders = useMemo(() => orders.filter((o) => o.captainId === captainId).sort((a, b) => b.createdAt - a.createdAt), [orders, captainId]);
  if (!view) return null;
  const c = view.captain;

  return (
    <Drawer
      open={!!captainId}
      onClose={onClose}
      title={c.fullName}
      subtitle={<div className="flex flex-wrap gap-2"><CaptainStatusBadge status={view.opStatus} /><FreshnessBadge freshness={view.freshness} /></div>}
      footer={
        <>
          <Button variant="outline" icon={<Wallet className="h-4 w-4" />} onClick={() => onRecharge(view)}>شحن المحفظة</Button>
          <Button variant="outline" icon={<Pencil className="h-4 w-4" />} onClick={() => onEdit(c)}>تعديل</Button>
        </>
      }
    >
      <Card className="p-4">
        <Toggle checked={c.status === 'active'} onChange={() => setConfirming(true)} label="حساب الكابتن مفعّل" description="الكابتن الموقوف لا يستقبل أي عروض" />
      </Card>
      <Card className="px-4 py-2">
        <dl className="divide-y divide-cream-dark">
          <DetailRow label="الهاتف"><span dir="ltr">{c.phone}</span></DetailRow>
          <DetailRow label="رصيد المحفظة">{formatMoney(view.balance)}</DetailRow>
          <DetailRow label="الأهلية">{view.eligibility.eligible ? 'مؤهل لاستقبال العروض' : describeReasons(view.eligibility.reasons, threshold)}</DetailRow>
          <DetailRow label="آخر موقع">{c.lastLocation ? `${formatRelative(c.lastLocation.recordedAt, now)} (محاكاة)` : '—'}</DetailRow>
          <DetailRow label="تاريخ التسجيل">{formatDate(c.createdAt)}</DetailRow>
          <DetailRow label="بيانات الدخول"><span dir="ltr">{c.username}</span></DetailRow>
        </dl>
      </Card>

      <CaptainTripHistory captainId={c.id} now={now} />

      <Card className="space-y-3 p-4">
        <h3 className="text-sm font-bold">التقييم الداخلي</h3>
        <CaptainRatingForm key={c.id} captain={c} />
      </Card>

      <Card className="p-4">
        <h3 className="mb-2 text-sm font-bold">التوصيلات ({captainOrders.length})</h3>
        <ul className="divide-y divide-cream-dark">
          {captainOrders.slice(0, 10).map((o) => (
            <li key={o.id} className="flex flex-wrap items-center gap-2 py-2 text-sm">
              <span className="font-mono font-bold" dir="ltr">{o.reference}</span>
              <span className="flex-1 text-ink-muted">{o.areaName} · {formatDateTime(o.createdAt)}</span>
              <OrderStatusBadge status={o.status} scheduled={o.requestType === 'scheduled'} />
            </li>
          ))}
          {captainOrders.length === 0 && <li className="py-4 text-center text-sm text-ink-muted">لا توجد توصيلات</li>}
        </ul>
      </Card>

      <CaptainStatusDialog captain={confirming ? c : null} onClose={() => setConfirming(false)} />
    </Drawer>
  );
}
