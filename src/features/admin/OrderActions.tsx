import { useState } from 'react';
import { Ban, Megaphone, UserCheck } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { DeliveryOrder } from '@/domain/types';
import { CANCELLABLE_STATUSES, isInQueue } from '@/domain/orderStatus';
import { Button, Dialog, Field, OpenDecision, Textarea } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { PrivateAssignDialog } from './PrivateAssignDialog';

/** Dispatch actions available to Admin for a single order. */
export function OrderActions({ order, size = 'sm' }: { order: DeliveryOrder; size?: 'sm' | 'md' }) {
  const broadcast = useAppStore((s) => s.settings.publicBroadcast);
  const dispatchPublic = useAppStore((s) => s.dispatchPublic);
  const cancelOrder = useAppStore((s) => s.cancelOrder);
  const [assigning, setAssigning] = useState(false);
  const [cancelling, setCancelling] = useState(false);
  const [reason, setReason] = useState('');

  const inQueue = isInQueue(order.status);
  const canCancel = CANCELLABLE_STATUSES.includes(order.status);
  if (!inQueue && !canCancel) return null;

  return (
    <div className="flex flex-wrap gap-2">
      {inQueue && (
        <>
          <Button
            size={size}
            variant="secondary"
            icon={<Megaphone className="h-4 w-4" />}
            disabled={!broadcast}
            title={broadcast ? undefined : 'البث العام متوقف'}
            onClick={() => reportResult(dispatchPublic(order.id), `تم نشر ${order.reference} للكباتن الأقرب المؤهلين`)}
          >
            نشر للعموم
          </Button>
          <Button size={size} icon={<UserCheck className="h-4 w-4" />} onClick={() => setAssigning(true)}>
            إسناد خاص
          </Button>
        </>
      )}
      {canCancel && (
        <Button size={size} variant="ghost" icon={<Ban className="h-4 w-4" />} onClick={() => setCancelling(true)}>
          إلغاء
        </Button>
      )}

      <PrivateAssignDialog order={assigning ? order : null} onClose={() => setAssigning(false)} />

      <Dialog
        open={cancelling}
        onClose={() => setCancelling(false)}
        size="sm"
        title={`إلغاء الطلب ${order.reference}؟`}
        footer={
          <>
            <Button variant="outline" onClick={() => setCancelling(false)}>
              تراجع
            </Button>
            <Button
              variant="danger"
              onClick={() => {
                if (reportResult(cancelOrder(order.id, reason), 'تم إلغاء الطلب')) {
                  setCancelling(false);
                  setReason('');
                }
              }}
            >
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
    </div>
  );
}
