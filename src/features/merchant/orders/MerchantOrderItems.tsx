import { useState } from 'react';
import { Bike, ChevronLeft, Phone } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { useNow } from '@/shared/hooks/application';
import type { DeliveryOrder } from '@/domain/types';
import { destinationText } from '@/domain/destination';
import { isActiveDelivery } from '@/domain/orderStatus';
import { isValidPhone } from '@/domain/phone';
import { formatMoney } from '@/domain/money';
import { formatAmmanDateTime } from '@/domain/time';
import { OrderStatusBadge } from '@/shared/components/StatusBadge';
import { DeliveryProgress } from '@/shared/components/OrderTimeline';
import { formatDateTime, formatRelative } from '@/shared/lib/format';
import { MerchantOrderDetail } from './MerchantOrderDetail';

/** Wording while no Captain is assigned yet — never implies acceptance. */
function waitingText(order: DeliveryOrder): string {
  if (order.requestType === 'scheduled') {
    return order.status === 'offered_privately' ? 'عُرض الطلب على كابتن وبانتظار قبوله.' : 'بانتظار تنسيق الإدارة لكابتن في الموعد المطلوب. لم يُسند كابتن بعد.';
  }
  if (order.status === 'awaiting_captain' || order.status === 'offered_privately') return 'جارٍ البحث عن كابتن قريب…';
  if (order.status === 'dispatch_expired') return 'لم يُسند كابتن بعد — فريق شهم يتابع الطلب.';
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
        <OrderStatusBadge status={order.status} scheduled={order.requestType === 'scheduled'} audience="merchant" />
        <span className="ms-auto text-xs text-ink-muted">آخر تحديث {formatRelative(order.updatedAt, now)}</span>
      </div>
      <p className="text-sm text-ink-soft">
        إلى <b>{destinationText(order)}</b> · {formatMoney(order.deliveryPrice)}
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
            <a href={`tel:${captain.phone}`} className="-my-3 inline-flex min-h-11 items-center gap-1 text-sm font-bold text-primary hover:underline">
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

/** A finished order (delivered or cancelled) in a compact row; the whole row opens its details. */
export function HistoryItem({ order }: { order: DeliveryOrder }) {
  const captain = useAppStore((s) => s.captains.find((c) => c.id === order.captainId));
  const [open, setOpen] = useState(false);
  return (
    <li>
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label={`عرض تفاصيل الطلب ${order.reference}`}
        className="flex w-full flex-wrap items-center gap-x-3 gap-y-1 px-5 py-3 text-start text-sm transition-colors hover:bg-cream/60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-secondary-300"
      >
      <span className="font-mono font-bold" dir="ltr">{order.reference}</span>
      <span className="min-w-0 flex-1 truncate text-ink-soft">
        {destinationText(order)}
      </span>
      <span className="whitespace-nowrap font-bold">{formatMoney(order.deliveryPrice)}</span>
      <OrderStatusBadge status={order.status} scheduled={order.requestType === 'scheduled'} audience="merchant" />
      <ChevronLeft className="h-4 w-4 shrink-0 text-ink-muted" aria-hidden />
      <span className="w-full text-xs text-ink-muted">
        {formatDateTime(order.createdAt)}
        {order.requestType === 'scheduled' && order.scheduledPickupAt !== undefined && ` · مؤجل لـ ${formatAmmanDateTime(order.scheduledPickupAt)}`}
        {captain && ` · ${captain.fullName}`}
      </span>
      </button>
      {open && <MerchantOrderDetail order={order} onClose={() => setOpen(false)} />}
    </li>
  );
}
