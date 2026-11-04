import { useState } from 'react';
import { Hourglass, Inbox, Radio, Timer, TriangleAlert, UserRound } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { useNow } from '@/application/hooks';
import type { DeliveryOrder } from '@/domain/types';
import { DISPATCH_ROUND_SEC, MAX_DISPATCH_ROUNDS } from '@/domain/dispatch';
import { isOffering } from '@/domain/orderStatus';
import { formatMoney } from '@/domain/money';
import { Badge, Card, CardHeader, EmptyState, OpenDecision, PageHeader, SimTag } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { formatRelative } from '@/shared/lib/format';
import { OrderActions } from '../OrderActions';
import { OrderDetailDrawer } from '../OrderDetailDrawer';
import { DispatchSummary } from './DispatchSummary';
import { OfferRound } from './OfferRound';

export function DispatchPage() {
  const now = useNow(1000);
  const orders = useAppStore((s) => s.orders);
  const merchants = useAppStore((s) => s.merchants);
  const settings = useAppStore((s) => s.settings);
  const demo = useAppStore((s) => s.demo);
  const [detailId, setDetailId] = useState<string | null>(null);

  const byAge = (a: DeliveryOrder, b: DeliveryOrder) => a.createdAt - b.createdAt;
  const waiting = orders.filter((o) => o.status === 'pending_dispatch').sort(byAge);
  const intervention = orders.filter((o) => o.status === 'dispatch_expired').sort(byAge);
  const offering = orders.filter((o) => isOffering(o.status));
  const merchantName = (id: string) => merchants.find((m) => m.id === id)?.businessName ?? '—';

  const summary = (o: DeliveryOrder) => (
    <div className="min-w-[240px] flex-1">
      <div className="flex flex-wrap items-center gap-2">
        <button className="font-mono font-bold text-primary hover:underline" dir="ltr" onClick={() => setDetailId(o.id)}>
          {o.reference}
        </button>
        <OrderStatusBadge status={o.status} />
        {o.dispatchMode === 'private' && <Badge tone="info">خاص</Badge>}
      </div>
      <p className="mt-1 text-sm text-ink-soft">
        <b>{merchantName(o.merchantId)}</b> ← {o.destination.label} ({o.areaName})
      </p>
      <p className="text-xs text-ink-muted">
        {formatMoney(o.deliveryPrice)} · أُنشئ {formatRelative(o.createdAt, now)}
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

      <div className="mb-6 grid gap-4 lg:grid-cols-3">
        <Card className="flex items-center gap-3 p-4">
          <Radio className={settings.publicBroadcast ? 'h-6 w-6 text-secondary' : 'h-6 w-6 text-amber-700'} />
          <div>
            <p className="text-xs text-ink-muted">البث العام</p>
            <p className="font-bold">{settings.publicBroadcast ? 'مفعّل' : 'متوقف — لا تُرسل عروض عامة جديدة؛ استخدم الإسناد الخاص أو فعّل البث'}</p>
          </div>
        </Card>
        <Card className="space-y-2 p-4 lg:col-span-2">
          <p className="text-sm font-bold">
            كل جولة {DISPATCH_ROUND_SEC} ثانية، بحد أقصى {MAX_DISPATCH_ROUNDS} جولات تلقائية. عند القبول تتوقف الجولات فوراً؛ وبعد الجولة الثالثة دون قبول يعود الطلب إلى طابور الإدارة.
          </p>
          <div className="flex flex-wrap items-center gap-2 text-sm">
            <SimTag>اختيار الكباتن في كل جولة — افتراض تجريبي</SimTag>
            <span className="text-ink-soft">
              {demo.offerPolicy === 'group' ? `أقرب ${demo.groupSize} كباتن مؤهلين لم يُعرض عليهم بعد — أول قبول يفوز` : 'الكابتن الأقرب التالي في كل جولة'} · ترتيب بالمسافة المستقيمة إلى التاجر
            </span>
          </div>
          <OpenDecision id="O-004 / O-005">من يستلم العرض في كل جولة (كابتن واحد أم مجموعة) وطريقة حساب القرب قرارات مفتوحة.</OpenDecision>
          <p className="text-xs text-ink-muted">في هذا النموذج تُدار الجولات بساعة محاكاة داخل المتصفح. في التشغيل الفعلي يجب أن يملكها الخادم (مهمة مجدولة محفوظة، وقبول/انتهاء ذرّي).</p>
        </Card>
      </div>

      <div className="grid gap-6 xl:grid-cols-2">
        <div className="space-y-6">
          <Card>
            <CardHeader title={`بحاجة لتدخل الإدارة (${intervention.length})`} description="انتهت جولات التوزيع دون قبول — لا تبدأ جولة جديدة إلا بإجراء من الإدارة" icon={<TriangleAlert className="h-5 w-5" />} />
            {intervention.length === 0 ? <EmptyState title="لا توجد طلبات تحتاج تدخلاً" /> : queueList(intervention)}
          </Card>
          <Card>
            <CardHeader title={`بانتظار التوزيع (${waiting.length})`} description="طلبات لم تُعرض بعد على الكباتن" icon={<Inbox className="h-5 w-5" />} />
            {waiting.length === 0 ? (
              <EmptyState icon={<Hourglass className="h-6 w-6" />} title="لا توجد طلبات بالانتظار" description="تظهر هنا الطلبات الجديدة عندما يكون البث العام متوقفاً، أو عند عودة عرض خاص." />
            ) : (
              queueList(waiting)
            )}
          </Card>
        </div>

        <Card>
          <CardHeader title={`عروض قائمة (${offering.length})`} description="الجولة الحالية والكباتن الذين عُرض عليهم الطلب" icon={<Timer className="h-5 w-5" />} />
          {offering.length === 0 ? (
            <EmptyState icon={<UserRound className="h-6 w-6" />} title="لا توجد عروض قائمة" />
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
