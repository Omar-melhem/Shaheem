import { Bike, Phone } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { useNow } from '@/shared/hooks/application';
import type { DeliveryOrder } from '@/domain/types';
import { isActiveDelivery } from '@/domain/orderStatus';
import { isValidPhone } from '@/domain/phone';
import { formatMoney } from '@/domain/money';
import { formatAmmanDateTime } from '@/domain/time';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { DeliveryProgress } from '@/shared/components/OrderTimeline';
import { formatDateTime, formatRelative } from '@/shared/lib/format';

/** Wording while no Captain is assigned yet — never implies acceptance. */
function waitingText(order: DeliveryOrder): string {
  if (order.requestType === 'scheduled') {
    return order.status === 'offered_privately' ? 'عُرض الطلب على كابتن وبانتظار قبوله.' : 'بانتظار تنسيق الإدارة لكابتن في الموعد المطلوب. لم يُسند كابتن بعد.';
  }
  if (order.status === 'awaiting_captain' || order.status === 'offered_privately') return 'جارٍ البحث عن كابتن قريب…';
  if (order.status === 'dispatch_expired') return 'لم يقبل أي كابتن بعد — فريق شهم يتابع الطلب.';
  return 'الطلب في انتظار التوزيع من فريق شهم.';
}

/** One active order: reference, status, last update, progress and the Captain when assigned. */
export function ActiveOrderItem({ order }: { order: DeliveryOrder }) {
  const now = useNow(5000);
  const captain = useAppStore((s) => s.captains.find((c) => c.id === order.captainId));
  const active = isActiveDelivery(order.status);
  return (
    <li className="space-y-3 px-5 py-4">
      <div className="flex flex-wrap items-center gap-2">
        <span className="font-mono font-bold" dir="ltr">{order.reference}</span>
        <OrderStatusBadge status={order.status} scheduled={order.requestType === 'scheduled'} />
        <span className="ms-auto text-xs text-ink-muted">آخر تحديث {formatRelative(order.updatedAt, now)}</span>
      </div>
      <p className="text-sm text-ink-soft">
        إلى <b>{order.destination.label}</b> ({order.areaName}) · {formatMoney(order.deliveryPrice)}
        {order.customerPhone && <span className="block text-xs text-ink-muted">هاتف العميل: <span dir="ltr">{order.customerPhone}</span></span>}
      </p>
      {order.requestType === 'scheduled' && order.scheduledPickupAt !== undefined && (
        <p className="rounded-lg bg-sand-light/30 px-3 py-1.5 text-xs">طلب مؤجل · موعد الاستلام <b>{formatAmmanDateTime(order.scheduledPickupAt)}</b></p>
      )}
      {active && <DeliveryProgress order={order} />}
      {captain && active ? (
        <div className="flex items-center gap-3 rounded-xl bg-cream px-3 py-2">
          <Bike className="h-5 w-5 text-primary" aria-hidden />
          <span className="flex-1 text-sm">الكابتن <b>{captain.fullName}</b></span>
          {isValidPhone(captain.phone) && (
            <a href={`tel:${captain.phone}`} className="inline-flex items-center gap-1 text-sm font-bold text-primary hover:underline">
              <Phone className="h-4 w-4" aria-hidden /> اتصال
            </a>
          )}
        </div>
      ) : (
        <p className="text-xs text-ink-muted">{waitingText(order)}</p>
      )}
    </li>
  );
}

/** A finished order (delivered or cancelled) in a compact row. */
export function HistoryItem({ order }: { order: DeliveryOrder }) {
  const captain = useAppStore((s) => s.captains.find((c) => c.id === order.captainId));
  return (
    <li className="flex flex-wrap items-center gap-x-3 gap-y-1 px-5 py-3 text-sm">
      <span className="font-mono font-bold" dir="ltr">{order.reference}</span>
      <span className="min-w-0 flex-1 truncate text-ink-soft">
        {order.destination.label} · {order.areaName}
      </span>
      <span className="whitespace-nowrap font-bold">{formatMoney(order.deliveryPrice)}</span>
      <OrderStatusBadge status={order.status} scheduled={order.requestType === 'scheduled'} />
      <span className="w-full text-xs text-ink-muted">
        {formatDateTime(order.createdAt)}
        {order.requestType === 'scheduled' && order.scheduledPickupAt !== undefined && ` · مؤجل لـ ${formatAmmanDateTime(order.scheduledPickupAt)}`}
        {captain && ` · ${captain.fullName}`}
      </span>
    </li>
  );
}
