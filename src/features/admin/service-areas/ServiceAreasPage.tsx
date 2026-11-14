import { useMemo, useState } from 'react';
import { ListPlus, Plus, Route, Shapes } from 'lucide-react';
import { useAppStore } from '@/app/state';
import type { ServiceArea } from '@/domain/types';
import { governorateName } from '@/domain/governorates';
import { topLevelAreas } from '@/domain/regions';
import { Button, Card, EmptyState, Field, OpenDecision, PageHeader, SearchField } from '@/shared/components/ui';
import { GovernorateSelect } from './GovernorateSelect';
import { ZoneDialog, type ZoneEditing } from './ZoneDialog';
import { ZoneStatusDialog } from './ZoneStatusDialog';
import { DeliveryRouteDialog } from './DeliveryRouteDialog';
import { DeliveryRoutesCard } from './DeliveryRoutesCard';
import { AreaImportDialog } from './AreaImportDialog';
import { AreaTreeTable } from './AreaTreeTable';

/**
 * Region catalogue (CR v1.4 §1): Governorate → City → Area → optional sections, managed by
 * name with no map or boundary anywhere on this page. Origin → destination routes stay below.
 */
export function ServiceAreasPage() {
  const areas = useAppStore((s) => s.areas);
  const [q, setQ] = useState('');
  const [governorateId, setGovernorateId] = useState('');
  const [editing, setEditing] = useState<ZoneEditing | null>(null);
  const [toggling, setToggling] = useState<ServiceArea | null>(null);
  const [addingRoute, setAddingRoute] = useState(false);
  const [importing, setImporting] = useState(false);

  const needle = q.trim().toLowerCase();
  const inGovernorate = areas.filter((a) => !governorateId || a.governorateId === governorateId);
  // Search matches areas or sections; a matching section keeps its parent visible.
  const visibleIds = useMemo(() => {
    if (!needle) return null;
    const hit = inGovernorate.filter((a) => [a.name, ...a.aliases].some((n) => n.toLowerCase().includes(needle)));
    return new Set([...hit.map((a) => a.id), ...hit.map((a) => a.parentId).filter((id): id is string => !!id)]);
  }, [inGovernorate, needle]);
  const roots = topLevelAreas(inGovernorate)
    .filter((a) => !visibleIds || visibleIds.has(a.id))
    .sort((a, b) => a.name.localeCompare(b.name, 'ar'));

  return (
    <>
      <PageHeader
        title="مناطق التوصيل"
        description="المحافظة ← المدينة ← المنطقة ← الأقسام. تُدار بالأسماء، ولكل منطقة وقسم سعر مستقل لكل تاجر من «أسعار التجار»."
        actions={
          <>
            <Button variant="outline" icon={<Route className="h-4 w-4" />} onClick={() => setAddingRoute(true)}>مسار توصيل جديد</Button>
            <Button variant="outline" icon={<ListPlus className="h-4 w-4" />} onClick={() => setImporting(true)}>استيراد مناطق</Button>
            <Button icon={<Plus className="h-4 w-4" />} onClick={() => setEditing({ mode: 'new' })}>منطقة جديدة</Button>
          </>
        }
      />

      <div className="space-y-6">
        <Card className="overflow-hidden">
          <div className="flex flex-wrap items-end gap-3 border-b border-cream-dark p-4">
            <Field label="المحافظة" htmlFor="areas-gov" className="w-48">
              <GovernorateSelect id="areas-gov" placeholder="كل المحافظات" value={governorateId} onChange={(e) => setGovernorateId(e.target.value)} />
            </Field>
            <SearchField label="بحث في المناطق والأقسام" className="min-w-0 w-full sm:w-auto sm:min-w-[200px] max-w-sm flex-1" placeholder="ابحث بالاسم أو الاسم البديل" value={q} onChange={(e) => setQ(e.target.value)} />
          </div>
          {roots.length === 0 ? (
            <EmptyState icon={<Shapes className="h-6 w-6" />} title="لا توجد مناطق" description={governorateId ? `لا توجد مناطق في ${governorateName(governorateId)} بعد.` : undefined} />
          ) : (
            <AreaTreeTable
              roots={roots}
              visibleIds={visibleIds}
              onEdit={(zone) => setEditing({ mode: 'edit', zone })}
              onAddSection={(parent) => setEditing({ mode: 'section', parent })}
              onToggle={setToggling}
            />
          )}
        </Card>
        <DeliveryRoutesCard governorateId={governorateId} />
        <OpenDecision id="CR-1.4 §1.2">قائمة المناطق الرسمية لم تُعتمد بعد؛ المناطق الحالية بيانات عرض. حدود المناطق القديمة محفوظة كبيانات سابقة ولا تُعدَّل من هنا.</OpenDecision>
      </div>

      <ZoneDialog editing={editing} onClose={() => setEditing(null)} />
      <ZoneStatusDialog zone={toggling} onClose={() => setToggling(null)} />
      <DeliveryRouteDialog open={addingRoute} onClose={() => setAddingRoute(false)} />
      <AreaImportDialog open={importing} onClose={() => setImporting(false)} />
    </>
  );
}
