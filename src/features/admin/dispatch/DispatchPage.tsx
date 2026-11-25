import { useMemo, useState } from 'react';
import { Inbox, Timer, TriangleAlert } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { useEligibleCaptainCount, useNow } from '@/shared/hooks/application';
import { dispatchQueues } from '@/application/dispatchQueues';
import type { DeliveryOrder } from '@/domain/types';
import { DISPATCH_ROUNDS, DISPATCH_ROUND_SEC, MAX_DISPATCH_ROUNDS, describeRound, describeQueueReason } from '@/domain/dispatch';
import { ORDER_GROUP_LABEL } from '@/domain/orderStatus';
import { formatMoney } from '@/domain/money';
import { destinationText } from '@/domain/destination';
import { Badge, Card, CardHeader, EmptyState, OpenDecision, PageHeader } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { formatRelative } from '@/shared/lib/format';
import { OrderActions } from '../OrderActions';
import { OrderDetailDrawer } from '../OrderDetailDrawer';
import { DispatchSummary } from './DispatchSummary';
import { OfferRound } from './OfferRound';
import { ScheduledQueueCard } from './ScheduledQueueCard';

/**
 * Distribution Center: «needs Admin» full width on top, then the scheduled and waiting queues
 * stacked on the right and live offers on the left; one column on small screens, queues first. Queue
 * membership comes from application/dispatchQueues.ts. Broadcasting is switched in the header.
 */
export function DispatchPage() {
  const now = useNow(1000);
  const orders = useAppStore((s) => s.orders);
  const merchants = useAppStore((s) => s.merchants);
  const eligibleNow = useEligibleCaptainCount();
  const [detailId, setDetailId] = useState<string | null>(null);
  const { scheduled, intervention, waiting, offering } = useMemo(() => dispatchQueues(orders), [orders]);
  const merchantName = (id: string) => merchants.find((m) => m.id === id)?.businessName ?? '—';

  const summary = (o: DeliveryOrder) => (
    <div className="min-w-0 basis-full flex-1 xl:basis-60">
      <div className="flex flex-wrap items-center gap-2">
        <button className="font-mono font-bold text-primary hover:underline" dir="ltr" onClick={() => setDetailId(o.id)}>
          {o.reference}
        </button>
        <OrderStatusBadge status={o.status} scheduled={o.requestType === 'scheduled'} />
        {o.dispatchMode === 'private' && <Badge tone="info">خاص</Badge>}
      </div>
      <p className="mt-1 text-sm text-ink-soft">
        <b>{merchantName(o.merchantId)}</b> ← {destinationText(o)}
      </p>
      <p className="text-xs text-ink-muted">
        {formatMoney(o.deliveryPrice)} · ينتظر منذ {formatRelative(o.createdAt, now)}
      </p>
      {o.queueReason && <p className="mt-1 text-xs font-bold text-red-800">السبب: {describeQueueReason(o.queueReason, eligibleNow)}</p>}
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

      <Card className="mb-6 space-y-2 px-4 py-3 text-sm">
        <p className="font-bold">
          {MAX_DISPATCH_ROUNDS} جولات تلقائية، {DISPATCH_ROUND_SEC} ثانية لكل جولة، من موقع التاجر — أول قبول يفوز، وبعدها يعود الطلب إلى الإدارة:
        </p>
        <ol className="flex flex-wrap gap-2 text-ink-soft">
          {DISPATCH_ROUNDS.map((policy, i) => (
            <li key={i} className="rounded-lg bg-cream px-2.5 py-1 text-xs"><b className="text-ink">الجولة {i + 1}:</b> {describeRound(policy)}</li>
          ))}
        </ol>
        <OpenDecision id="بانتظار التأكيد">«3 إلى 5 كيلو» مفهومة كأقرب 3 كباتن ضمن 5 كم، وعدد الجولة الثانية (3) ومدة الجولتين الثانية والثالثة مقترحة. الجولات هنا بساعة محاكاة داخل المتصفح؛ في الإنتاج يديرها الخادم.</OpenDecision>
      </Card>

      {/* Most urgent queue, full width (owner review 2026-11-21). */}
      <Card className="mb-6">
        <CardHeader title={`${ORDER_GROUP_LABEL.needs_admin} (${intervention.length})`} description="انتهت جولات التوزيع دون قبول — لا تبدأ جولة جديدة إلا بإجراء من الإدارة" icon={<TriangleAlert className="h-5 w-5" />} />
        {intervention.length === 0 ? <EmptyState compact title="لا توجد طلبات بحاجة لتدخل الإدارة حالياً" /> : queueList(intervention)}
      </Card>

      <div className="grid items-start gap-6 lg:grid-cols-[minmax(0,1.35fr)_minmax(0,1fr)] lg:[grid-template-areas:'queues_offers']">
        <div className="min-w-0 space-y-6 lg:[grid-area:queues]">
          <ScheduledQueueCard orders={scheduled} now={now} onOpen={setDetailId} />
          <Card>
            <CardHeader title={`${ORDER_GROUP_LABEL.pending_dispatch} (${waiting.length})`} description="طلبات لم تُعرض بعد على الكباتن" icon={<Inbox className="h-5 w-5" />} />
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
