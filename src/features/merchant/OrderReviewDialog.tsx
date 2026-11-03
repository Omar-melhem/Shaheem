import type { ReactNode } from 'react';
import { CheckCircle2 } from 'lucide-react';
import type { Money } from '@/domain/types';
import { formatMoney } from '@/domain/money';
import { Button, DetailRow, Dialog } from '@/shared/components/ui';

export interface ReviewState {
  fee: Money;
  /** Set when Admin changed the fee while the form was open (Spec §10). */
  changedFrom?: Money;
}

/** Confirmation step before a Captain request; the fee shown here is locked on confirm. */
export function OrderReviewDialog({
  review,
  rows,
  submitting,
  onClose,
  onConfirm,
}: {
  review: ReviewState | null;
  rows: Array<[label: string, value: ReactNode]>;
  submitting: boolean;
  onClose: () => void;
  onConfirm: () => void;
}) {
  const changed = review?.changedFrom !== undefined;
  return (
    <Dialog
      open={!!review}
      onClose={onClose}
      title={changed ? 'تم تحديث رسوم التوصيل' : 'مراجعة طلب الكابتن'}
      footer={
        <>
          <Button variant="outline" onClick={onClose}>تعديل</Button>
          <Button onClick={onConfirm} loading={submitting} icon={<CheckCircle2 className="h-4 w-4" />}>
            {changed ? 'تأكيد بالرسوم الجديدة' : 'تأكيد طلب الكابتن'}
          </Button>
        </>
      }
    >
      {review && (
        <>
          {changed && (
            <p className="mb-3 rounded-xl border border-amber-300 bg-amber-50 p-3 text-sm text-amber-900" role="alert">
              غيّرت إدارة شهم رسوم هذه المنطقة من {formatMoney(review.changedFrom!)} إلى <b>{formatMoney(review.fee)}</b>. راجع الرسوم الجديدة قبل التأكيد.
            </p>
          )}
          <dl className="divide-y divide-cream-dark text-sm">
            {rows.map(([label, value]) => (
              <DetailRow key={label} label={label}>{value}</DetailRow>
            ))}
            <DetailRow label="رسوم التوصيل"><span className="text-lg font-extrabold text-primary">{formatMoney(review.fee)}</span></DetailRow>
          </dl>
          <p className="mt-3 text-xs text-ink-muted">تُحفظ الرسوم مع الطلب عند التأكيد ولا تتغير لاحقاً.</p>
        </>
      )}
    </Dialog>
  );
}
