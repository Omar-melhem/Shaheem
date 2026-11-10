import { useAppStore } from '@/application/store';
import type { ServiceArea } from '@/domain/types';
import { Button, Dialog } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';

/** Confirms activating / deactivating a central zone and explains the impact. */
export function ZoneStatusDialog({ zone, onClose }: { zone: ServiceArea | null; onClose: () => void }) {
  const setStatus = useAppStore((s) => s.setServiceAreaStatus);
  const coverage = useAppStore((s) => s.coverage);
  const areas = useAppStore((s) => s.areas);
  const orders = useAppStore((s) => s.orders);
  const active = zone?.status === 'active';
  const merchantsUsing = zone ? coverage.filter((c) => c.areaId === zone.id).length : 0;
  const sections = zone ? areas.filter((a) => a.parentId === zone.id).length : 0;
  const orderCount = zone ? orders.filter((o) => o.areaId === zone.id).length : 0;

  return (
    <Dialog
      open={!!zone}
      onClose={onClose}
      size="sm"
      title={active ? `إيقاف منطقة ${zone?.name}؟` : `تفعيل منطقة ${zone?.name}؟`}
      footer={
        <>
          <Button variant="outline" onClick={onClose}>تراجع</Button>
          <Button
            variant={active ? 'danger' : 'secondary'}
            onClick={() => {
              if (zone && reportResult(setStatus(zone.id, !active), 'تم تحديث حالة المنطقة')) onClose();
            }}
          >
            {active ? 'إيقاف المنطقة' : 'تفعيل'}
          </Button>
        </>
      }
    >
      {active ? (
        <div className="space-y-2 text-sm text-ink-soft">
          <p>أثر الإيقاف:</p>
          <ul className="list-disc space-y-1 ps-5">
            <li>لن تُقبل طلبات جديدة لعملاء داخلها لدى <b>{merchantsUsing}</b> تاجر.</li>
            {sections > 0 && <li>أقسامها (<b>{sections}</b>) تتوقف معها ولا تُقبل طلبات إليها.</li>}
            <li>الطلبات السابقة (<b>{orderCount}</b>) تبقى كما هي برسومها المحفوظة.</li>
            <li>أسعار التجار لهذه المنطقة تبقى محفوظة وتعود عند إعادة التفعيل.</li>
          </ul>
        </div>
      ) : (
        <p className="text-sm text-ink-soft">ستعود المنطقة متاحة للتجار المفعّلة لديهم بأسعارهم المحفوظة.</p>
      )}
    </Dialog>
  );
}
