import { useAppStore } from '@/app/state';
import type { Captain } from '@/domain/types';
import { ConfirmDialog } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';

/** Confirms activating / deactivating a Captain account (row action and drawer toggle). */
export function CaptainStatusDialog({ captain, onClose }: { captain: Captain | null; onClose: () => void }) {
  const setCaptainStatus = useAppStore((s) => s.setCaptainStatus);
  const active = captain?.status === 'active';
  return (
    <ConfirmDialog
      open={!!captain}
      onClose={onClose}
      onConfirm={() => captain && reportResult(setCaptainStatus(captain.id, !active), active ? 'تم إيقاف الكابتن' : 'تم تفعيل الكابتن')}
      title={active ? `إيقاف حساب ${captain?.fullName ?? ''}؟` : `تفعيل حساب ${captain?.fullName ?? ''}؟`}
      description={active ? 'ستُسحب أي عروض قائمة له ولن يستقبل عروضاً جديدة.' : 'سيتمكن الكابتن من التحول إلى متاح واستقبال العروض.'}
      variant={active ? 'danger' : 'secondary'}
    />
  );
}
