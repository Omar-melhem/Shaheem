import { useMemo } from 'react';
import { CheckCircle2 } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { formatMoney } from '@/domain/money';
import { areaLabel } from '@/domain/regions';
import { ammanDayKey, formatAmmanTime, lastThreeAmmanDays } from '@/domain/time';
import { Badge, Card } from '@/shared/components/ui';

const DAY_LABELS = ['اليوم', 'أمس', 'قبل أمس'] as const;

/**
 * Trips this Captain actually delivered today, yesterday and the day before, by Amman calendar
 * day of the delivery time (CR v1.4 §7). A view only: nothing older is removed. No commission
 * is shown as deducted, because none is charged in this prototype.
 */
export function CaptainTripHistory({ captainId, now }: { captainId: string; now: number }) {
  const orders = useAppStore((s) => s.orders);
  const merchants = useAppStore((s) => s.merchants);
  const areas = useAppStore((s) => s.areas);

  const days = lastThreeAmmanDays(now);
  const { byDay, missingTime } = useMemo(() => {
    const delivered = orders.filter((o) => o.captainId === captainId && o.status === 'delivered');
    const map = new Map<string, typeof delivered>(days.map((d) => [d, []]));
    for (const o of delivered) {
      if (o.deliveredAt === undefined) continue;
      map.get(ammanDayKey(o.deliveredAt))?.push(o);
    }
    map.forEach((list) => list.sort((a, b) => b.deliveredAt! - a.deliveredAt!));
    return { byDay: map, missingTime: delivered.filter((o) => o.deliveredAt === undefined).length };
  }, [orders, captainId, days]);
  const total = days.reduce((n, d) => n + (byDay.get(d)?.length ?? 0), 0);

  return (
    <Card className="space-y-3 p-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h3 className="flex items-center gap-2 text-sm font-bold"><CheckCircle2 className="h-4 w-4 text-secondary" aria-hidden /> الرحلات المكتملة — آخر 3 أيام</h3>
        <Badge tone="success">{total} رحلة</Badge>
      </div>
      <p className="text-xs text-ink-muted">حسب وقت التسليم وبتوقيت عمّان. الطلبات الملغاة أو غير المكتملة لا تُحسب.</p>
      {days.map((day, i) => {
        const list = byDay.get(day) ?? [];
        return (
          <section key={day} className="rounded-xl bg-cream/60 p-3">
            <p className="mb-1 flex items-center justify-between text-sm font-bold">
              <span>{DAY_LABELS[i]} <span className="text-xs font-normal text-ink-muted" dir="ltr">{day}</span></span>
              <span className="text-xs text-ink-muted">{list.length}</span>
            </p>
            {list.length === 0 ? (
              <p className="text-xs text-ink-muted">لا توجد رحلات مكتملة.</p>
            ) : (
              <ul className="divide-y divide-cream-deep">
                {list.map((o) => {
                  const area = areas.find((a) => a.id === o.areaId);
                  return (
                    <li key={o.id} className="flex flex-wrap items-center gap-x-3 gap-y-0.5 py-2 text-sm">
                      <span className="w-14 text-xs text-ink-muted">{formatAmmanTime(o.deliveredAt!)}</span>
                      <span className="font-mono text-xs font-bold" dir="ltr">{o.reference}</span>
                      <span className="min-w-0 flex-1 truncate text-ink-soft">
                        {merchants.find((m) => m.id === o.merchantId)?.businessName} ← {area ? areaLabel(area, areas) : o.areaName}
                      </span>
                      <span className="font-bold">{formatMoney(o.deliveryPrice)}</span>
                      <span className="w-full text-xs text-ink-muted">العمولة المخصومة: — (غير مفعّلة في هذا النموذج)</span>
                    </li>
                  );
                })}
              </ul>
            )}
          </section>
        );
      })}
      {missingTime > 0 && <p className="text-xs text-amber-800">{missingTime} رحلة مكتملة بلا وقت تسليم مسجّل، فلا تُنسب لأي يوم.</p>}
    </Card>
  );
}
