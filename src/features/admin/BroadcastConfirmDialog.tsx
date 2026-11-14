import { useAppStore } from '@/app/state';
import { ConfirmDialog } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';

/**
 * Confirmation for switching public broadcasting. Every broadcast switch (header,
 * settings) goes through this, so there is one state (`settings.publicBroadcast`) and one flow.
 */
export function BroadcastConfirmDialog({ next, onClose }: { next: boolean | null; onClose: () => void }) {
  const offering = useAppStore((s) => s.orders.filter((o) => o.status === 'awaiting_captain').length);
  const setPublicBroadcast = useAppStore((s) => s.setPublicBroadcast);
  return (
    <ConfirmDialog
      open={next !== null}
      onClose={onClose}
      onConfirm={() => next !== null && reportResult(setPublicBroadcast(next), next ? 'تم تفعيل البث العام' : 'تم إيقاف البث العام')}
      title={next ? 'تفعيل البث العام؟' : 'إيقاف البث العام؟'}
      description={
        next
          ? 'ستدخل الطلبات الجديدة عملية التوزيع العام تلقائياً. الطلبات الموجودة في الطابور تبقى حتى تنشرها يدوياً.'
          : `لن تُعرض الطلبات الجديدة على الكباتن المؤهلين، وتبقى في طابور الإدارة للتوزيع اليدوي.${offering ? ` ستُسحب العروض العامة القائمة لـ ${offering} طلب وتعود إلى الطابور.` : ''} التوصيلات النشطة تستمر والإسناد الخاص يبقى متاحاً.`
      }
      confirmLabel={next ? 'تفعيل' : 'تأكيد الإيقاف'}
      cancelLabel="إلغاء"
      variant={next ? 'secondary' : 'danger'}
    />
  );
}
