import { useState } from 'react';
import { ArrowLeft, Route, Trash2 } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { DeliveryRoute } from '@/domain/types';
import { governorateName } from '@/domain/governorates';
import { Button, Card, CardHeader, ConfirmDialog, EmptyState } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';

/** Saved origin → destination routes, optionally limited to one Governorate. */
export function DeliveryRoutesCard({ governorateId }: { governorateId: string }) {
  const routes = useAppStore((s) => s.routes);
  const areas = useAppStore((s) => s.areas);
  const removeRoute = useAppStore((s) => s.removeRoute);
  const [deleting, setDeleting] = useState<DeliveryRoute | null>(null);
  const areaName = (id: string) => areas.find((a) => a.id === id)?.name ?? '—';
  const visible = routes.filter((r) => !governorateId || r.governorateId === governorateId);

  return (
    <Card>
      <CardHeader title={`مسارات التوصيل (${visible.length})`} description="من منطقة إلى منطقة داخل المحافظة" icon={<Route className="h-5 w-5" />} />
      {visible.length === 0 ? (
        <EmptyState title="لا توجد مسارات بعد" description="أضف مساراً من زر «مسار توصيل جديد»." />
      ) : (
        <ul className="divide-y divide-cream-dark">
          {visible.map((r) => (
            <li key={r.id} className="flex items-center gap-3 px-5 py-3">
              <div className="min-w-0 flex-1">
                <p className="flex flex-wrap items-center gap-2 font-bold">
                  {areaName(r.originAreaId)} <ArrowLeft className="h-4 w-4 text-primary" aria-label="إلى" /> {areaName(r.destinationAreaId)}
                </p>
                <p className="text-xs text-ink-muted">{governorateName(r.governorateId)}</p>
              </div>
              <Button size="sm" variant="ghost" aria-label="حذف المسار" onClick={() => setDeleting(r)}>
                <Trash2 className="h-4 w-4 text-red-700" />
              </Button>
            </li>
          ))}
        </ul>
      )}
      <ConfirmDialog
        open={!!deleting}
        onClose={() => setDeleting(null)}
        onConfirm={() => deleting && reportResult(removeRoute(deleting.id), 'تم حذف المسار')}
        title="حذف مسار التوصيل؟"
        description={deleting ? `من «${areaName(deleting.originAreaId)}» إلى «${areaName(deleting.destinationAreaId)}». لا يؤثر الحذف على الأسعار أو الطلبات.` : undefined}
        confirmLabel="حذف"
        variant="danger"
      />
    </Card>
  );
}
