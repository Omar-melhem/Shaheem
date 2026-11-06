import { useEffect, useRef } from 'react';
import { AlertTriangle, CheckCircle2 } from 'lucide-react';
import { NO_EXACT_LOCATION } from '@/domain/destination';
import type { Money } from '@/domain/types';
import { formatMoney } from '@/domain/money';
import { Button, DetailRow, Dialog } from '@/shared/components/ui';

export interface ReviewState {
  fee: Money;
  /** Parsed once when the review opened; this is the amount the order is created with. */
  orderValue: Money;
  /** Set when Admin changed the fee while the form was open (Spec §10). */
  changedFrom?: Money;
}

export interface ReviewDetails {
  pickupName: string;
  pickupAddress: string;
  areaName: string;
  /** Place name or pin label; null for an area-only order. */
  exactLocation: string | null;
  customerName?: string;
  customerPhone?: string;
}

/** Confirmation step before a Captain request; the fee shown here is locked on confirm. */
export function OrderReviewDialog({
  review,
  details,
  submitting,
  error,
  onClose,
  onConfirm,
}: {
  review: ReviewState | null;
  details: ReviewDetails;
  submitting: boolean;
  error: string | null;
  onClose: () => void;
  onConfirm: () => void;
}) {
  const changed = review?.changedFrom !== undefined;
  const confirmRef = useRef<HTMLButtonElement>(null);

  // The confirm button lost focus while disabled; hand it back so retrying works from the keyboard.
  useEffect(() => {
    if (error || changed) confirmRef.current?.focus();
  }, [error, changed]);

  return (
    <Dialog
      open={!!review}
      onClose={onClose}
      title={changed ? 'تم تحديث رسوم التوصيل' : 'تأكيد طلب الكابتن'}
      description="يرجى مراجعة تفاصيل الطلب قبل التأكيد"
      footer={
        <>
          <Button variant="outline" onClick={onClose} disabled={submitting}>رجوع للتعديل</Button>
          <Button ref={confirmRef} onClick={onConfirm} loading={submitting} icon={<CheckCircle2 className="h-4 w-4" />}>
            {submitting ? 'جاري إنشاء الطلب...' : changed ? 'تأكيد بالرسوم الجديدة' : 'تأكيد الطلب'}
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
          {error && (
            <p className="mb-3 flex items-start gap-2 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">
              <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden />
              <span>لم يُنشأ الطلب: {error}</span>
            </p>
          )}
          <dl className="divide-y divide-cream-dark text-sm">
            <DetailRow label="موقع الاستلام">
              {details.pickupName}
              <span className="block text-xs font-normal text-ink-muted">{details.pickupAddress}</span>
            </DetailRow>
            <DetailRow label="منطقة التوصيل">{details.areaName}</DetailRow>
            <DetailRow label="الموقع الدقيق">
              {details.exactLocation ?? <span className="text-amber-800">{NO_EXACT_LOCATION}</span>}
            </DetailRow>
            {details.customerName && <DetailRow label="اسم العميل">{details.customerName}</DetailRow>}
            {details.customerPhone && <DetailRow label="هاتف العميل"><span dir="ltr">{details.customerPhone}</span></DetailRow>}
          </dl>
          <dl className="mt-3 divide-y divide-cream-deep rounded-xl bg-cream px-3 text-sm">
            <DetailRow label="قيمة الطلب"><span className="text-base font-extrabold text-ink">{formatMoney(review.orderValue)}</span></DetailRow>
            <DetailRow label="رسوم التوصيل"><span className="text-lg font-extrabold text-primary">{formatMoney(review.fee)}</span></DetailRow>
          </dl>
          <p className="mt-3 text-xs text-ink-muted">تُحفظ الرسوم مع الطلب عند التأكيد ولا تتغير لاحقاً.</p>
        </>
      )}
    </Dialog>
  );
}
