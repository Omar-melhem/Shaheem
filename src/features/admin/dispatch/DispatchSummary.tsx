import { CalendarClock, CheckCircle2, Hourglass, Radio, TriangleAlert } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { ACTIVE_DELIVERY_STATUSES, isInQueue } from '@/domain/orderStatus';
import { isAutoDispatchEligible } from '@/domain/dispatch';
import { StatCard } from '@/shared/components/ui';

/** Dispatch states kept visibly apart (FU-1.2 §5.4); scheduled requests are counted on their own (CR v1.4 §6.2). */
export function DispatchSummary() {
  const orders = useAppStore((s) => s.orders);
  const immediate = orders.filter(isAutoDispatchEligible);
  const count = (pred: (status: string) => boolean) => immediate.filter((o) => pred(o.status)).length;
  const scheduled = orders.filter((o) => o.requestType === 'scheduled' && (isInQueue(o.status) || o.status === 'offered_privately')).length;
  const waiting = count((s) => s === 'pending_dispatch');
  const offering = count((s) => s === 'awaiting_captain' || s === 'offered_privately');
  const accepted = orders.filter((o) => (ACTIVE_DELIVERY_STATUSES as string[]).includes(o.status)).length;
  const intervention = count((s) => s === 'dispatch_expired');

  return (
    <div className="mb-6 grid grid-cols-1 sm:grid-cols-2 gap-4 lg:grid-cols-5">
      <StatCard label="بانتظار التوزيع" value={waiting} icon={<Hourglass className="h-5 w-5" />} tone={waiting ? 'warning' : 'neutral'} hint="لم تُعرض بعد" />
      <StatCard label="معروضة الآن" value={offering} icon={<Radio className="h-5 w-5" />} tone="warning" hint="جولة قائمة على الكباتن" />
      <StatCard label="تم القبول" value={accepted} icon={<CheckCircle2 className="h-5 w-5" />} tone="secondary" hint="مُسندة لكابتن وقيد التوصيل" />
      <StatCard label="طلبات مؤجلة" value={scheduled} icon={<CalendarClock className="h-5 w-5" />} tone={scheduled ? 'primary' : 'neutral'} hint="تنسيق يدوي من الإدارة" />
      <StatCard label="بحاجة لتدخل الإدارة" value={intervention} icon={<TriangleAlert className="h-5 w-5" />} tone={intervention ? 'danger' : 'neutral'} hint="انتهت الجولات دون قبول" />
    </div>
  );
}
