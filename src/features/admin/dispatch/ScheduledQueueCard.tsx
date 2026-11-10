import { CalendarClock, Copy } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { DeliveryOrder } from '@/domain/types';
import { formatMoney } from '@/domain/money';
import { areaLabel } from '@/domain/regions';
import { formatAmmanDateTime } from '@/domain/time';
import { Badge, Button, Card, CardHeader, EmptyState } from '@/shared/components/ui';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { toast } from '@/shared/components/toast';
import { formatRelative } from '@/shared/lib/format';
import { OrderActions } from '../OrderActions';

const HOUR = 3_600_000;

/** Non-sensitive summary for the Captains' WhatsApp group: no customer name or phone. */
export function whatsappMessage(order: DeliveryOrder, merchantName: string, merchantAddress: string, destination: string): string {
  return [
    `طلب مؤجل من شهم — ${order.reference}`,
    `الاستلام: ${merchantName} (${merchantAddress})`,
    `موعد الاستلام من المتجر: ${formatAmmanDateTime(order.scheduledPickupAt!)}`,
    `منطقة التوصيل: ${destination}`,
    `رسوم التوصيل: ${formatMoney(order.deliveryPrice)}`,
    'من يستطيع استلامه؟',
  ].join('\n');
}

async function copyText(text: string) {
  try {
    await navigator.clipboard.writeText(text);
    toast.success('تم نسخ الرسالة', { description: 'الصقها في مجموعة الكباتن على واتساب.' });
  } catch {
    toast.error('تعذّر النسخ تلقائياً', { description: 'انسخ النص يدوياً من تفاصيل الطلب.' });
  }
}

/**
 * Scheduled requests waiting for manual coordination (CR v1.4 §6.2). They never enter public
 * broadcast: Admin asks Captains on WhatsApp (copy the message), then assigns privately here.
 */
export function ScheduledQueueCard({ orders, now, onOpen }: { orders: DeliveryOrder[]; now: number; onOpen: (id: string) => void }) {
  const merchants = useAppStore((s) => s.merchants);
  const areas = useAppStore((s) => s.areas);

  return (
    <Card>
      <CardHeader
        title={`طلبات مؤجلة — تنسيق يدوي (${orders.length})`}
        description="لا تُعرض تلقائياً على الكباتن. نسّق عبر مجموعة واتساب ثم استخدم الإسناد الخاص."
        icon={<CalendarClock className="h-5 w-5" />}
      />
      {orders.length === 0 ? (
        <EmptyState compact title="لا توجد طلبات مؤجلة حالياً" />
      ) : (
        <ul className="divide-y divide-cream-dark">
          {orders.map((o) => {
            const merchant = merchants.find((m) => m.id === o.merchantId);
            const area = areas.find((a) => a.id === o.areaId);
            const destination = area ? areaLabel(area, areas) : o.areaName;
            const left = (o.scheduledPickupAt ?? 0) - now;
            return (
              <li key={o.id} className="space-y-2 px-5 py-4">
                <div className="flex flex-wrap items-center gap-2">
                  <button className="font-mono font-bold text-primary hover:underline" dir="ltr" onClick={() => onOpen(o.id)}>{o.reference}</button>
                  <OrderStatusBadge status={o.status} scheduled />
                  {left < 0 ? <Badge tone="danger">فات موعد الاستلام</Badge> : left < 2 * HOUR ? <Badge tone="warning">قريب</Badge> : null}
                </div>
                <p className="text-sm">
                  الاستلام: <b>{formatAmmanDateTime(o.scheduledPickupAt!)}</b> <span className="text-xs text-ink-muted">({left < 0 ? 'فات' : 'بعد'} {formatRelative(now - Math.abs(left), now).replace('منذ ', '')})</span>
                </p>
                <p className="text-sm text-ink-soft">
                  <b>{merchant?.businessName}</b> ← {destination} · {formatMoney(o.deliveryPrice)} · أُنشئ {formatRelative(o.createdAt, now)}
                </p>
                <div className="flex flex-wrap gap-2">
                  <Button size="sm" variant="outline" icon={<Copy className="h-4 w-4" />} onClick={() => copyText(whatsappMessage(o, merchant?.businessName ?? '', merchant?.address ?? '', destination))}>
                    نسخ رسالة واتساب
                  </Button>
                  <OrderActions order={o} />
                </div>
              </li>
            );
          })}
        </ul>
      )}
    </Card>
  );
}
