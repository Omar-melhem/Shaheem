import { useState } from 'react';
import { Hourglass, Inbox, Radio, Timer, UserRound } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { useNow } from '@/application/hooks';
import type { DeliveryOrder, DispatchOffer } from '@/domain/types';
import { isInQueue } from '@/domain/orderStatus';
import { formatMoney } from '@/domain/money';
import { formatDistance } from '@/domain/geo';
import { Badge, Card, CardHeader, EmptyState, OpenDecision, PageHeader, SimTag } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { formatCountdown, formatRelative } from '@/shared/lib/format';
import { OrderActions } from './OrderActions';
import { OrderDetailDrawer } from './OrderDetailDrawer';

const OFFER_STATUS_LABEL: Record<DispatchOffer['status'], string> = {
  pending: 'بانتظار الرد',
  accepted: 'قَبِل',
  rejected: 'رفض',
  expired: 'انتهت المهلة',
  withdrawn: 'سُحب',
};
const OFFER_TONE = { pending: 'warning', accepted: 'success', rejected: 'danger', expired: 'neutral', withdrawn: 'neutral' } as const;

export function DispatchPage() {
  const now = useNow(1000);
  const orders = useAppStore((s) => s.orders);
  const offers = useAppStore((s) => s.offers);
  const merchants = useAppStore((s) => s.merchants);
  const captains = useAppStore((s) => s.captains);
  const settings = useAppStore((s) => s.settings);
  const demo = useAppStore((s) => s.demo);
  const [detailId, setDetailId] = useState<string | null>(null);

  const queue = orders.filter((o) => isInQueue(o.status)).sort((a, b) => a.createdAt - b.createdAt);
  const offering = orders.filter((o) => o.status === 'awaiting_captain' || o.status === 'offered_privately');
  const merchantName = (id: string) => merchants.find((m) => m.id === id)?.businessName ?? '—';
  const captainName = (id: string) => captains.find((c) => c.id === id)?.fullName ?? '—';

  const OrderSummary = ({ o }: { o: DeliveryOrder }) => (
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
    </div>
  );

  return (
    <>
      <PageHeader title="مركز التوزيع" description="طابور الطلبات، العروض القائمة على الكباتن، والإسناد الخاص." />

      <div className="mb-6 grid gap-4 lg:grid-cols-3">
        <Card className="flex items-center gap-3 p-4">
          <Radio className={settings.publicBroadcast ? 'h-6 w-6 text-secondary' : 'h-6 w-6 text-amber-700'} />
          <div>
            <p className="text-xs text-ink-muted">البث العام</p>
            <p className="font-bold">{settings.publicBroadcast ? 'مفعّل' : 'متوقف — استخدم الإسناد الخاص أو فعّل البث من لوحة التحكم'}</p>
          </div>
        </Card>
        <Card className="space-y-2 p-4 lg:col-span-2">
          <div className="flex flex-wrap items-center gap-2 text-sm">
            <SimTag>سياسة العرض التجريبية</SimTag>
            <span className="font-bold">
              {demo.offerPolicy === 'group' ? `أقرب ${demo.groupSize} كباتن مؤهلين في آن واحد — أول قبول يفوز` : 'تسلسلي — الأقرب أولاً ثم التالي'}
            </span>
            <span className="text-ink-muted">· مهلة {demo.offerTimeoutSec} ث · ترتيب بالمسافة المستقيمة إلى التاجر</span>
          </div>
          <OpenDecision id="O-004 / O-005">طريقة حساب القرب (مستقيمة / طرق / زمن وصول) وتسلسل العروض قرارات مفتوحة؛ يمكن تغيير الافتراض من أدوات العرض.</OpenDecision>
        </Card>
      </div>

      <div className="grid gap-6 xl:grid-cols-2">
        <Card>
          <CardHeader title={`طابور الإدارة (${queue.length})`} description="طلبات بانتظار التوزيع أو انتهى توزيعها دون إسناد" icon={<Inbox className="h-5 w-5" />} />
          {queue.length === 0 ? (
            <EmptyState icon={<Hourglass className="h-6 w-6" />} title="الطابور فارغ" description="ستظهر هنا الطلبات الجديدة عندما يكون البث العام متوقفاً، أو عندما لا يقبلها أي كابتن." />
          ) : (
            <ul className="divide-y divide-cream-dark">
              {queue.map((o) => (
                <li key={o.id} className="flex flex-wrap items-start gap-3 px-5 py-4">
                  <OrderSummary o={o} />
                  <OrderActions order={o} />
                </li>
              ))}
            </ul>
          )}
        </Card>

        <Card>
          <CardHeader title={`عروض قائمة (${offering.length})`} description="الكباتن الذين عُرض عليهم الطلب في الجولة الحالية" icon={<Timer className="h-5 w-5" />} />
          {offering.length === 0 ? (
            <EmptyState icon={<UserRound className="h-6 w-6" />} title="لا توجد عروض قائمة" />
          ) : (
            <ul className="divide-y divide-cream-dark">
              {offering.map((o) => {
                const roundOffers = offers.filter((x) => x.orderId === o.id && x.round === o.dispatchRound).sort((a, b) => (a.rank ?? 0) - (b.rank ?? 0));
                return (
                  <li key={o.id} className="space-y-3 px-5 py-4">
                    <div className="flex flex-wrap items-start gap-3">
                      <OrderSummary o={o} />
                      <OrderActions order={o} />
                    </div>
                    <ul className="space-y-1.5 rounded-xl bg-cream p-3">
                      {roundOffers.map((x) => (
                        <li key={x.id} className="flex flex-wrap items-center gap-2 text-sm">
                          {x.rank && <span className="w-6 text-center text-xs font-bold text-ink-muted">#{x.rank}</span>}
                          <span className="flex-1 font-medium">{captainName(x.captainId)}</span>
                          {x.distanceMeters !== undefined && <span className="text-xs text-ink-muted">{formatDistance(x.distanceMeters)}</span>}
                          <Badge tone={OFFER_TONE[x.status]}>{OFFER_STATUS_LABEL[x.status]}</Badge>
                          {x.status === 'pending' && <span className="w-12 font-mono text-xs font-bold text-amber-800" dir="ltr">{formatCountdown(x.expiresAt - now)}</span>}
                        </li>
                      ))}
                    </ul>
                  </li>
                );
              })}
            </ul>
          )}
        </Card>
      </div>

      <OrderDetailDrawer orderId={detailId} onClose={() => setDetailId(null)} />
    </>
  );
}
