import { CalendarClock, Hourglass, Radio, TriangleAlert, Truck } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { ORDER_GROUP_LABEL, countByGroup } from '@/domain/orderStatus';
import { StatCard } from '@/shared/components/ui';

/**
 * Dispatch states kept visibly apart (FU-1.2 §5.4). Counts and labels come from the shared
 * `countByGroup` / ORDER_GROUP_LABEL, so they match the dashboard; scheduled requests are their
 * own group (CR v1.4 §6.2).
 */
export function DispatchSummary() {
  const orders = useAppStore((s) => s.orders);
  const c = countByGroup(orders);

  return (
    <div className="mb-6 grid grid-cols-1 sm:grid-cols-2 gap-4 lg:grid-cols-5">
      <StatCard label={ORDER_GROUP_LABEL.pending_dispatch} value={c.pending_dispatch} icon={<Hourglass className="h-5 w-5" />} tone={c.pending_dispatch ? 'warning' : 'neutral'} hint="لم تُعرض بعد على الكباتن" />
      <StatCard label={ORDER_GROUP_LABEL.offered} value={c.offered} icon={<Radio className="h-5 w-5" />} tone="warning" hint="بث عام أو عرض خاص قائم" />
      <StatCard label={ORDER_GROUP_LABEL.active} value={c.active} icon={<Truck className="h-5 w-5" />} tone="secondary" hint="من القبول حتى التسليم" />
      <StatCard label={ORDER_GROUP_LABEL.scheduled_pending} value={c.scheduled_pending} icon={<CalendarClock className="h-5 w-5" />} tone={c.scheduled_pending ? 'primary' : 'neutral'} hint="تنسيق يدوي من الإدارة" />
      <StatCard label={ORDER_GROUP_LABEL.needs_admin} value={c.needs_admin} icon={<TriangleAlert className="h-5 w-5" />} tone={c.needs_admin ? 'danger' : 'neutral'} hint="انتهت الجولات دون قبول" />
    </div>
  );
}
