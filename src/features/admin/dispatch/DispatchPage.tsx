import { useMemo, useState } from 'react';
import { Inbox, Timer, TriangleAlert } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { useNow } from '@/application/hooks';
import { dispatchQueues } from '@/application/dispatchQueues';
import type { DeliveryOrder } from '@/domain/types';
import { DISPATCH_ROUND_SEC, MAX_DISPATCH_ROUNDS } from '@/domain/dispatch';
import { formatMoney } from '@/domain/money';
import { Badge, Card, CardHeader, EmptyState, OpenDecision, PageHeader, SimTag } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { formatRelative } from '@/shared/lib/format';
import { OrderActions } from '../OrderActions';
import { OrderDetailDrawer } from '../OrderDetailDrawer';
import { DispatchSummary } from './DispatchSummary';
import { OfferRound } from './OfferRound';
import { ScheduledQueueCard } from './ScheduledQueueCard';

/**
 * Distribution Center: three order queues stacked on the right (scheduled → needs Admin →
 * waiting) and live offers on the left; one column on small screens, queues first. Queue
 * membership comes from application/dispatchQueues.ts. Broadcasting is switched in the header.
 */
export function DispatchPage() {
  const now = useNow(1000);
  const orders = useAppStore((s) => s.orders);
  const merchants = useAppStore((s) => s.merchants);
  const demo = useAppStore((s) => s.demo);
  const [detailId, setDetailId] = useState<string | null>(null);
  const { scheduled, intervention, waiting, offering } = useMemo(() => dispatchQueues(orders), [orders]);
  const merchantName = (id: string) => merchants.find((m) => m.id === id)?.businessName ?? '—';

  const summary = (o: DeliveryOrder) => (
    <div className="min-w-[240px] flex-1">
      <div className="flex flex-wrap items-center gap-2">
        <button className="font-mono font-bold text-primary hover:underline" dir="ltr" onClick={() => setDetailId(o.id)}>
          {o.reference}
        </button>
        <OrderStatusBadge status={o.status} scheduled={o.requestType === 'scheduled'} />
        {o.dispatchMode === 'private' && <Badge tone="info">خاص</Badge>}
      </div>
      <p className="mt-1 text-sm text-ink-soft">
        <b>{merchantName(o.merchantId)}</b> ← {o.destination.label} ({o.areaName})
      </p>
      <p className="text-xs text-ink-muted">
        {formatMoney(o.deliveryPrice)} · ينتظر منذ {formatRelative(o.createdAt, now)}
      </p>
      {o.queueReason && <p className="mt-1 text-xs font-bold text-red-800">السبب: {o.queueReason}</p>}
    </div>
  );

  const queueList = (list: DeliveryOrder[]) => (
    <ul className="divide-y divide-cream-dark">
      {list.map((o) => (
        <li key={o.id} className="flex flex-wrap items-start gap-3 px-5 py-4">
          {summary(o)}
          <OrderActions order={o} />
        </li>
      ))}
    </ul>
  );

  return (
    <>
      <PageHeader title="مركز التوزيع" description="طابور الطلبات، الجولات القائمة على الكباتن، والإسناد الخاص." />

      <DispatchSummary />

      <Card className="mb-6 flex flex-wrap items-center gap-x-4 gap-y-2 px-4 py-3 text-sm">
        <p className="font-bold">
          كل جولة {DISPATCH_ROUND_SEC} ثانية، بحد أقصى {MAX_DISPATCH_ROUNDS} جولات تلقائية؛ بعدها يعود الطلب إلى الإدارة.
        </p>
        <SimTag>اختيار الكباتن في كل جولة — افتراض تجريبي</SimTag>
        <span className="text-ink-soft">
          {demo.offerPolicy === 'group' ? `أقرب ${demo.groupSize} كباتن مؤهلين لم يُعرض عليهم بعد — أول قبول يفوز` : 'الكابتن الأقرب التالي في كل جولة'}
        </span>
        <OpenDecision id="O-004 / O-005">من يستلم العرض في كل جولة وطريقة حساب القرب قرارات مفتوحة؛ الجولات هنا بساعة محاكاة داخل المتصفح.</OpenDecision>
      </Card>

      <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,1.35fr)_minmax(0,1fr)] lg:[grid-template-areas:'queues_offers']">
        <div className="min-w-0 space-y-6 lg:[grid-area:queues]">
          <ScheduledQueueCard orders={scheduled} now={now} onOpen={setDetailId} />
          <Card>
            <CardHeader title={`بحاجة لتدخل الإدارة (${intervention.length})`} description="انتهت جولات التوزيع دون قبول — لا تبدأ جولة جديدة إلا بإجراء من الإدارة" icon={<TriangleAlert className="h-5 w-5" />} />
            {intervention.length === 0 ? <EmptyState compact title="لا توجد طلبات بحاجة لتدخل الإدارة حالياً" /> : queueList(intervention)}
          </Card>
          <Card>
            <CardHeader title={`بانتظار التوزيع (${waiting.length})`} description="طلبات لم تُعرض بعد على الكباتن" icon={<Inbox className="h-5 w-5" />} />
            {waiting.length === 0 ? <EmptyState compact title="لا توجد طلبات بانتظار التوزيع حالياً" /> : queueList(waiting)}
          </Card>
        </div>

        <Card className="min-w-0 lg:[grid-area:offers]">
          <CardHeader title={`العروض القائمة (${offering.length})`} description="الجولة الحالية والكباتن الذين عُرض عليهم الطلب" icon={<Timer className="h-5 w-5" />} />
          {offering.length === 0 ? (
            <EmptyState compact title="لا توجد عروض قائمة حالياً" />
          ) : (
            <ul className="divide-y divide-cream-dark">
              {offering.map((o) => (
                <li key={o.id} className="space-y-3 px-5 py-4">
                  <div className="flex flex-wrap items-start gap-3">
                    {summary(o)}
                    <OrderActions order={o} />
                  </div>
                  <OfferRound order={o} now={now} />
                </li>
              ))}
            </ul>
          )}
        </Card>
      </div>

      <OrderDetailDrawer orderId={detailId} onClose={() => setDetailId(null)} />
    </>
  );
}
