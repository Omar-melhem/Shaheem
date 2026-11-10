import { useState } from 'react';
import { Ban, Megaphone, UserCheck } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { DeliveryOrder } from '@/domain/types';
import { CANCELLABLE_STATUSES, isInQueue } from '@/domain/orderStatus';
import { isAutoDispatchEligible } from '@/domain/dispatch';
import { Button } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { PrivateAssignDialog } from './PrivateAssignDialog';
import { CancelOrderDialog } from './CancelOrderDialog';

/** Dispatch actions available to Admin for a single order. */
export function OrderActions({ order, size = 'sm' }: { order: DeliveryOrder; size?: 'sm' | 'md' }) {
  const broadcast = useAppStore((s) => s.settings.publicBroadcast);
  const dispatchPublic = useAppStore((s) => s.dispatchPublic);
  const [assigning, setAssigning] = useState(false);
  const [cancelling, setCancelling] = useState(false);

  const inQueue = isInQueue(order.status);
  const canCancel = CANCELLABLE_STATUSES.includes(order.status);
  if (!inQueue && !canCancel) return null;

  return (
    <div className="flex flex-wrap gap-2">
      {inQueue && (
        <>
          {isAutoDispatchEligible(order) && <Button
            size={size}
            variant="secondary"
            icon={<Megaphone className="h-4 w-4" />}
            disabled={!broadcast}
            title={broadcast ? undefined : 'البث العام متوقف'}
            onClick={() => reportResult(dispatchPublic(order.id), `تم نشر ${order.reference} للكباتن الأقرب المؤهلين`)}
          >
            نشر للعموم
          </Button>}
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
      <CancelOrderDialog order={cancelling ? order : null} onClose={() => setCancelling(false)} />
    </div>
  );
}
