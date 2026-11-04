import { CheckCircle2, Hourglass, Radio, TriangleAlert } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { ACTIVE_DELIVERY_STATUSES } from '@/domain/orderStatus';
import { StatCard } from '@/shared/components/ui';

/** The four dispatch states kept visibly apart (FU-1.2 §5.4). */
export function DispatchSummary() {
  const orders = useAppStore((s) => s.orders);
  const count = (pred: (status: string) => boolean) => orders.filter((o) => pred(o.status)).length;
  const waiting = count((s) => s === 'pending_dispatch');
  const offering = count((s) => s === 'awaiting_captain' || s === 'offered_privately');
  const accepted = count((s) => (ACTIVE_DELIVERY_STATUSES as string[]).includes(s));
  const intervention = count((s) => s === 'dispatch_expired');

  return (
    <div className="mb-6 grid grid-cols-2 gap-4 lg:grid-cols-4">
      <StatCard label="بانتظار التوزيع" value={waiting} icon={<Hourglass className="h-5 w-5" />} tone={waiting ? 'warning' : 'neutral'} hint="لم تُعرض بعد" />
      <StatCard label="معروضة الآن" value={offering} icon={<Radio className="h-5 w-5" />} tone="warning" hint="جولة قائمة على الكباتن" />
      <StatCard label="تم القبول" value={accepted} icon={<CheckCircle2 className="h-5 w-5" />} tone="secondary" hint="مُسندة لكابتن وقيد التوصيل" />
      <StatCard label="بحاجة لتدخل الإدارة" value={intervention} icon={<TriangleAlert className="h-5 w-5" />} tone={intervention ? 'danger' : 'neutral'} hint="انتهت الجولات دون قبول" />
    </div>
  );
}
