import { useState } from 'react';
import { useAppStore } from '@/app/state';
import type { DeliveryOrder } from '@/domain/types';
import { Button, Dialog, Field, OpenDecision, Textarea } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';

/**
 * Admin cancellation with confirmation. The store enforces the existing policy
 * (pre-acceptance states only, no financial effect — O-029 open); the reason is optional.
 */
export function CancelOrderDialog({ order, onClose }: { order: DeliveryOrder | null; onClose: () => void }) {
  const cancelOrder = useAppStore((s) => s.cancelOrder);
  const [reason, setReason] = useState('');
  const [submitting, setSubmitting] = useState(false);

  const close = () => {
    setReason('');
    onClose();
  };
  const confirm = () => {
    if (!order || submitting) return; // no double submission
    setSubmitting(true);
    const ok = reportResult(cancelOrder(order.id, reason), `تم إلغاء الطلب ${order.reference}`);
    setSubmitting(false);
    if (ok) close();
  };

  return (
    <Dialog
      open={!!order}
      onClose={close}
      size="sm"
      title={order ? `إلغاء الطلب ${order.reference}؟` : ''}
      footer={
        <>
          <Button variant="outline" onClick={close} disabled={submitting}>
            تراجع
          </Button>
          <Button variant="danger" onClick={confirm} loading={submitting}>
            تأكيد الإلغاء
          </Button>
        </>
      }
    >
      <div className="space-y-3">
        <Field label="سبب الإلغاء" optional>
          <Textarea value={reason} onChange={(e) => setReason(e.target.value)} placeholder="مثال: طلب التاجر الإلغاء هاتفياً" />
        </Field>
        <OpenDecision id="O-029">سياسة الإلغاء غير معتمدة. يتيح هذا النموذج الإلغاء من الإدارة قبل قبول الكابتن فقط، ودون أي أثر مالي.</OpenDecision>
      </div>
    </Dialog>
  );
}
