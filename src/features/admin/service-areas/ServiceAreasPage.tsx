import { useState } from 'react';
import { Pencil, PenTool, Plus, Route, Shapes } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { ServiceArea } from '@/domain/types';
import { governorateName } from '@/domain/governorates';
import { Badge, Button, Card, EmptyState, Field, OpenDecision, PageHeader, SearchField, Toggle } from '@/shared/components/ui';
import { formatDate } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';
import { GovernorateSelect } from './GovernorateSelect';
import { ZoneDialog } from './ZoneDialog';
import { ZoneStatusDialog } from './ZoneStatusDialog';
import { DeliveryRouteDialog } from './DeliveryRouteDialog';
import { DeliveryRoutesCard } from './DeliveryRoutesCard';
import { ServiceAreaPolygonEditor } from './ServiceAreaPolygonEditor';

const HEADERS = ['المنطقة', 'المحافظة', 'أسماء بديلة', 'الحدود', 'تجار مفعّلون', 'طلبات', 'الحالة', ''];

/**
 * Central delivery zones grouped by Governorate (FU-1.2 §7), their polygon boundaries
 * (used to match customer pins), and origin → destination delivery routes.
 */
export function ServiceAreasPage() {
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const orders = useAppStore((s) => s.orders);

  const [q, setQ] = useState('');
  const [governorateId, setGovernorateId] = useState('');
  const [editing, setEditing] = useState<ServiceArea | 'new' | null>(null);
  const [toggling, setToggling] = useState<ServiceArea | null>(null);
  const [drawingId, setDrawingId] = useState<string | null>(null);
  const [addingRoute, setAddingRoute] = useState(false);

  const needle = q.trim().toLowerCase();
  const inGovernorate = areas.filter((a) => !governorateId || a.governorateId === governorateId);
  const filtered = inGovernorate.filter((a) => !needle || [a.name, ...a.aliases].some((n) => n.toLowerCase().includes(needle)));
  const merchantsUsing = (id: string) => prices.filter((p) => p.areaId === id && p.status === 'active').length;

  return (
    <>
      <PageHeader
        title="مناطق التوصيل"
        description="المحافظة ← المنطقة ← مسارات التوصيل. تُنشأ كل منطقة مرة واحدة مع حدودها على الخريطة، ثم تُضاف لتغطية التجار برسوم خاصة بكل تاجر."
        actions={
          <>
            <Button variant="outline" icon={<Route className="h-4 w-4" />} onClick={() => setAddingRoute(true)}>مسار توصيل جديد</Button>
            <Button icon={<Plus className="h-4 w-4" />} onClick={() => setEditing('new')}>منطقة جديدة</Button>
          </>
        }
      />

      <div className="grid gap-6 xl:grid-cols-[1fr_440px]">
        <div className="space-y-6">
          <Card className="overflow-hidden">
            <div className="flex flex-wrap items-end gap-3 border-b border-cream-dark p-4">
              <Field label="المحافظة" htmlFor="areas-gov" className="w-48">
                <GovernorateSelect id="areas-gov" placeholder="كل المحافظات" value={governorateId} onChange={(e) => setGovernorateId(e.target.value)} />
              </Field>
              <SearchField label="بحث في المناطق" className="min-w-[220px] max-w-sm flex-1" placeholder="ابحث بالاسم أو الاسم البديل" value={q} onChange={(e) => setQ(e.target.value)} />
            </div>
            {filtered.length === 0 ? (
              <EmptyState icon={<Shapes className="h-6 w-6" />} title="لا توجد مناطق" description={governorateId ? `لا توجد مناطق في ${governorateName(governorateId)} بعد.` : undefined} />
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full min-w-[820px] text-sm">
                  <thead className="bg-cream text-xs text-ink-muted">
                    <tr>
                      {HEADERS.map((h, i) => (
                        <th key={i} scope="col" className="px-4 py-3 text-start font-bold">{h}</th>
                      ))}
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-cream-dark">
                    {filtered.map((a) => (
                      <tr key={a.id} className={cn(a.status !== 'active' && 'opacity-70')}>
                        <td className="px-4 py-3">
                          <p className="font-bold">{a.name}</p>
                          {a.notes && <p className="text-xs text-ink-muted">{a.notes}</p>}
                          <p className="text-[11px] text-ink-muted">حُدّثت {formatDate(a.updatedAt)}</p>
                        </td>
                        <td className="px-4 py-3">{governorateName(a.governorateId)}</td>
                        <td className="px-4 py-3 text-xs text-ink-soft">{a.aliases.join('، ') || '—'}</td>
                        <td className="px-4 py-3">{a.polygon.length >= 3 ? <Badge tone="success">مرسومة</Badge> : <Badge tone="warning">غير مرسومة</Badge>}</td>
                        <td className="px-4 py-3">{merchantsUsing(a.id)}</td>
                        <td className="px-4 py-3">{orders.filter((o) => o.areaId === a.id).length}</td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2">
                            <Toggle checked={a.status === 'active'} onChange={() => setToggling(a)} label={<span className="sr-only">تفعيل {a.name}</span>} />
                            <Badge tone={a.status === 'active' ? 'success' : 'neutral'}>{a.status === 'active' ? 'نشطة' : 'متوقفة'}</Badge>
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex gap-1">
                            <Button size="sm" variant="ghost" icon={<Pencil className="h-3.5 w-3.5" />} onClick={() => setEditing(a)}>تعديل</Button>
                            <Button size="sm" variant="ghost" icon={<PenTool className="h-3.5 w-3.5" />} onClick={() => setDrawingId(a.id)}>الحدود</Button>
                          </div>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </Card>
          <DeliveryRoutesCard governorateId={governorateId} />
        </div>

        <div className="space-y-3">
          <ServiceAreaPolygonEditor areas={inGovernorate} drawing={areas.find((a) => a.id === drawingId) ?? null} onDone={() => setDrawingId(null)} />
          <p className="text-xs text-ink-muted">يُطابق موقع العميل مع المنطقة من حدودها على الخريطة؛ المنطقة بلا حدود لا يمكن مطابقتها. الرسوم ثابتة لكل تاجر ومنطقة ولا تعتمد على المسافة.</p>
          <OpenDecision id="FU-14.7">قائمة المحافظات والمناطق المعتمدة وطريقة صيانة الحدود لم تُحدَّد بعد؛ المحافظات هنا هي محافظات الأردن الاثنتا عشرة.</OpenDecision>
        </div>
      </div>

      <ZoneDialog zone={editing} onClose={() => setEditing(null)} />
      <ZoneStatusDialog zone={toggling} onClose={() => setToggling(null)} />
      <DeliveryRouteDialog open={addingRoute} onClose={() => setAddingRoute(false)} />
    </>
  );
}
