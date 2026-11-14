import { useMemo, useState } from 'react';
import { useAppStore } from '@/app/state';
import { useCaptainViews, useNow } from '@/shared/hooks/application';
import type { DeliveryOrder } from '@/domain/types';
import { haversineMeters, formatDistance } from '@/domain/geo';
import { describeReasons } from '@/domain/eligibility';
import { formatMoney } from '@/domain/money';
import { Button, Dialog, OpenDecision } from '@/shared/components/ui';
import { CaptainStatusBadge, FreshnessBadge } from '@/shared/components/StatusBadge';
import { reportResult } from '@/shared/components/toast';
import { cn } from '@/shared/lib/cn';

/** Private/manual dispatch: offer an order exclusively to one Captain (SRS §4.8). */
export function PrivateAssignDialog({ order, onClose }: { order: DeliveryOrder | null; onClose: () => void }) {
  const now = useNow(5000);
  const views = useCaptainViews(now);
  const threshold = useAppStore((s) => s.demo.walletThreshold);
  const timeout = useAppStore((s) => s.demo.offerTimeoutSec);
  const assignPrivate = useAppStore((s) => s.assignPrivate);
  const [selected, setSelected] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const ranked = useMemo(() => {
    if (!order) return [];
    return views
      .map((v) => ({ ...v, distance: v.captain.lastLocation ? haversineMeters(v.captain.lastLocation.position, order.pickup.position) : Infinity }))
      .sort((a, b) => Number(b.eligibility.eligible) - Number(a.eligibility.eligible) || a.distance - b.distance);
  }, [views, order]);

  const close = () => {
    setSelected(null);
    onClose();
  };

  const submit = () => {
    if (!order || !selected) return;
    setSubmitting(true);
    const ok = reportResult(assignPrivate(order.id, selected), 'تم إرسال العرض الخاص للكابتن');
    setSubmitting(false);
    if (ok) close();
  };

  return (
    <Dialog
      open={!!order}
      onClose={close}
      size="lg"
      title={`إسناد خاص — ${order?.reference ?? ''}`}
      description="يظهر العرض للكابتن المختار فقط. يُعاد التحقق من الأهلية عند الإرسال وعند القبول."
      footer={
        <>
          <Button variant="outline" onClick={close}>
            إلغاء
          </Button>
          <Button onClick={submit} disabled={!selected} loading={submitting}>
            إرسال العرض الخاص
          </Button>
        </>
      }
    >
      {order && (
        <div className="space-y-3">
          <div className="rounded-xl bg-cream px-4 py-3 text-sm">
            <b>{order.areaName}</b> · {order.destination.label} · {formatMoney(order.deliveryPrice)}
          </div>
          <ul className="space-y-2" role="radiogroup" aria-label="اختر الكابتن">
            {ranked.map((v) => {
              const disabled = !v.eligibility.eligible;
              return (
                <li key={v.captain.id}>
                  <button
                    role="radio"
                    aria-checked={selected === v.captain.id}
                    disabled={disabled}
                    onClick={() => setSelected(v.captain.id)}
                    className={cn(
                      'flex w-full flex-wrap items-center gap-3 rounded-xl border p-3 text-start transition-colors',
                      selected === v.captain.id ? 'border-primary bg-primary-50' : 'border-cream-deep bg-white hover:bg-cream',
                      disabled && 'cursor-not-allowed opacity-60 hover:bg-white',
                    )}
                  >
                    <div className="min-w-0 flex-1">
                      <p className="font-bold">{v.captain.fullName}</p>
                      <p className="text-xs text-ink-muted">
                        {Number.isFinite(v.distance) ? `${formatDistance(v.distance)} من التاجر (خط مستقيم)` : 'لا يوجد موقع'} · رصيد {formatMoney(v.balance)}
                      </p>
                      {disabled && <p className="mt-1 text-xs font-medium text-red-700">غير مؤهل: {describeReasons(v.eligibility.reasons, threshold)}</p>}
                    </div>
                    <CaptainStatusBadge status={v.opStatus} />
                    <FreshnessBadge freshness={v.freshness} />
                  </button>
                </li>
              );
            })}
          </ul>
          <OpenDecision id="O-006 / O-031">مهلة العرض الخاص {timeout} ثانية (قيمة تجريبية). عند الرفض أو انتهاء المهلة يعود الطلب إلى طابور الإدارة. تجاوز قيود الأهلية غير مسموح.</OpenDecision>
        </div>
      )}
    </Dialog>
  );
}
