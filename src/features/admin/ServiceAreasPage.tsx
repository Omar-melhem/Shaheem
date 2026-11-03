import { useState } from 'react';
import { Marker, Polygon, Polyline, Tooltip } from 'react-leaflet';
import { Check, Pencil, PenTool, Plus, Shapes, Undo2, X } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { LatLng, ServiceArea } from '@/domain/types';
import { Badge, Button, Card, Dialog, EmptyState, Field, Input, PageHeader, Textarea, Toggle, SearchField } from '@/shared/components/ui';
import { BaseMap, FitBounds, MapClickHandler } from '@/shared/components/map/BaseMap';
import { vertexIcon } from '@/shared/components/map/markers';
import { reportResult } from '@/shared/components/toast';
import { formatDate } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';

/**
 * Central delivery-zone list (Zone-Based Pricing Spec §4): each zone is created
 * once and reused by every Merchant. Boundaries are optional and display-only.
 */
export function ServiceAreasPage() {
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const orders = useAppStore((s) => s.orders);
  const updateZone = useAppStore((s) => s.updateZone);
  const setStatus = useAppStore((s) => s.setServiceAreaStatus);

  const [q, setQ] = useState('');
  const [editing, setEditing] = useState<ServiceArea | 'new' | null>(null);
  const [toggling, setToggling] = useState<ServiceArea | null>(null);
  const [drawingId, setDrawingId] = useState<string | null>(null);
  const [points, setPoints] = useState<LatLng[]>([]);

  const filtered = areas.filter((a) => !q.trim() || [a.name, ...a.aliases].some((n) => n.toLowerCase().includes(q.trim().toLowerCase())));
  const drawingArea = areas.find((a) => a.id === drawingId);
  const finishDraw = () => {
    if (drawingId && reportResult(updateZone(drawingId, { polygon: points }), 'تم حفظ حدود المنطقة على الخريطة')) {
      setDrawingId(null);
      setPoints([]);
    }
  };

  const merchantsUsing = (id: string) => prices.filter((p) => p.areaId === id && p.status === 'active').length;

  return (
    <>
      <PageHeader
        title="مناطق التوصيل"
        description="القائمة المركزية لمناطق التوصيل. تُنشأ كل منطقة مرة واحدة ثم تُضاف لتغطية التجار مع رسوم خاصة بكل تاجر."
        actions={<Button icon={<Plus className="h-4 w-4" />} onClick={() => setEditing('new')}>منطقة جديدة</Button>}
      />

      <div className="grid gap-6 xl:grid-cols-[1fr_440px]">
        <Card className="overflow-hidden">
          <div className="border-b border-cream-dark p-4">
            <SearchField label="بحث في المناطق" className="max-w-sm" placeholder="ابحث بالاسم أو الاسم البديل" value={q} onChange={(e) => setQ(e.target.value)} />
          </div>
          {filtered.length === 0 ? (
            <EmptyState icon={<Shapes className="h-6 w-6" />} title="لا توجد مناطق" />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full min-w-[720px] text-sm">
                <thead className="bg-cream text-xs text-ink-muted">
                  <tr>
                    {['المنطقة', 'أسماء بديلة', 'تجار مفعّلون', 'طلبات', 'الحالة', ''].map((h, i) => (
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
                      <td className="px-4 py-3 text-xs text-ink-soft">{a.aliases.join('، ') || '—'}</td>
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
                          <Button size="sm" variant="ghost" icon={<PenTool className="h-3.5 w-3.5" />} onClick={() => { setDrawingId(a.id); setPoints([]); }}>الحدود</Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>

        <div className="space-y-3">
          <div className="relative">
            <BaseMap className={cn('h-[460px]', drawingId && 'ring-4 ring-primary-200')} label="حدود مناطق التوصيل">
              <FitBounds points={areas.flatMap((a) => a.polygon)} fitKey="areas" maxZoom={13} />
              {drawingId && <MapClickHandler onClick={(p) => setPoints((ps) => [...ps, p])} />}
              {areas
                .filter((a) => a.polygon.length >= 3)
                .map((a) => (
                  <Polygon
                    key={a.id}
                    positions={a.polygon.map((p) => [p.lat, p.lng] as [number, number])}
                    pathOptions={{ color: a.status === 'active' ? '#263D34' : '#8A8580', weight: 2, dashArray: a.status === 'active' ? undefined : '6 6', fillOpacity: 0.12 }}
                    interactive={!drawingId}
                  >
                    <Tooltip permanent direction="center" className="!border-0 !bg-white/90 !text-xs !font-bold !shadow">{a.name}</Tooltip>
                  </Polygon>
                ))}
              {drawingId && points.length > 0 && (
                <>
                  {points.length >= 3 ? (
                    <Polygon positions={points.map((p) => [p.lat, p.lng] as [number, number])} pathOptions={{ color: '#8C2335', weight: 2, fillOpacity: 0.2 }} />
                  ) : (
                    <Polyline positions={points.map((p) => [p.lat, p.lng] as [number, number])} pathOptions={{ color: '#8C2335', weight: 2 }} />
                  )}
                  {points.map((p, i) => <Marker key={i} position={[p.lat, p.lng]} icon={vertexIcon()} />)}
                </>
              )}
            </BaseMap>
            {drawingArea && (
              <div className="absolute inset-x-3 top-3 z-[500] rounded-2xl bg-white p-3 shadow-pop">
                <p className="text-sm font-bold">رسم حدود «{drawingArea.name}» — اضغط على الخريطة ({points.length} نقاط)</p>
                <div className="mt-2 flex flex-wrap gap-2">
                  <Button size="sm" icon={<Check className="h-4 w-4" />} onClick={finishDraw} disabled={points.length < 3}>حفظ</Button>
                  <Button size="sm" variant="outline" icon={<Undo2 className="h-4 w-4" />} onClick={() => setPoints((ps) => ps.slice(0, -1))} disabled={!points.length}>تراجع</Button>
                  <Button size="sm" variant="ghost" icon={<X className="h-4 w-4" />} onClick={() => setDrawingId(null)}>إلغاء</Button>
                </div>
              </div>
            )}
          </div>
          <p className="text-xs text-ink-muted">الحدود اختيارية وتُستخدم للعرض على الخريطة فقط. رسوم التوصيل تُحدد من المنطقة التي يختارها التاجر، ولا تعتمد على المسافة أو موقع GPS للعميل.</p>
        </div>
      </div>

      <ZoneDialog zone={editing} onClose={() => setEditing(null)} />

      <Dialog
        open={!!toggling}
        onClose={() => setToggling(null)}
        size="sm"
        title={toggling?.status === 'active' ? `إيقاف منطقة ${toggling?.name}؟` : `تفعيل منطقة ${toggling?.name}؟`}
        footer={
          <>
            <Button variant="outline" onClick={() => setToggling(null)}>تراجع</Button>
            <Button
              variant={toggling?.status === 'active' ? 'danger' : 'secondary'}
              onClick={() => {
                if (toggling && reportResult(setStatus(toggling.id, toggling.status !== 'active'), 'تم تحديث حالة المنطقة')) setToggling(null);
              }}
            >
              {toggling?.status === 'active' ? 'إيقاف المنطقة' : 'تفعيل'}
            </Button>
          </>
        }
      >
        {toggling &&
          (toggling.status === 'active' ? (
            <div className="space-y-2 text-sm text-ink-soft">
              <p>أثر الإيقاف:</p>
              <ul className="list-disc space-y-1 ps-5">
                <li>ستختفي من قائمة المناطق لدى <b>{merchantsUsing(toggling.id)}</b> تاجر ولن تُقبل طلبات جديدة إليها.</li>
                <li>الطلبات السابقة (<b>{orders.filter((o) => o.areaId === toggling.id).length}</b>) تبقى كما هي برسومها المحفوظة.</li>
                <li>أسعار التجار لهذه المنطقة تبقى محفوظة وتعود عند إعادة التفعيل.</li>
              </ul>
            </div>
          ) : (
            <p className="text-sm text-ink-soft">ستعود المنطقة متاحة للتجار المفعّلة لديهم بأسعارهم المحفوظة.</p>
          ))}
      </Dialog>
    </>
  );
}

function ZoneDialog({ zone, onClose }: { zone: ServiceArea | 'new' | null; onClose: () => void }) {
  const createZone = useAppStore((s) => s.createZone);
  const updateZone = useAppStore((s) => s.updateZone);
  const [form, setForm] = useState({ name: '', aliases: '', notes: '' });
  const [lastKey, setLastKey] = useState<string | null>(null);
  const key = zone === 'new' ? 'new' : zone?.id ?? null;
  if (key !== lastKey) {
    setLastKey(key);
    setForm(zone && zone !== 'new' ? { name: zone.name, aliases: zone.aliases.join('، '), notes: zone.notes ?? '' } : { name: '', aliases: '', notes: '' });
  }

  const submit = () => {
    const input = { name: form.name, aliases: form.aliases.split(/[،,]/), notes: form.notes };
    const result = zone === 'new' ? createZone(input) : zone ? updateZone(zone.id, input) : null;
    if (result && reportResult(result, zone === 'new' ? 'تمت إضافة المنطقة للقائمة المركزية' : 'تم حفظ المنطقة')) onClose();
  };

  return (
    <Dialog
      open={!!zone}
      onClose={onClose}
      title={zone === 'new' ? 'منطقة توصيل جديدة' : 'تعديل المنطقة'}
      footer={
        <>
          <Button variant="outline" onClick={onClose}>إلغاء</Button>
          <Button onClick={submit}>حفظ</Button>
        </>
      }
    >
      <div className="space-y-4">
        <Field label="اسم المنطقة بالعربية" required>
          <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="مثال: ضاحية الرشيد" />
        </Field>
        <Field label="أسماء بديلة / تهجئات" optional hint="افصل بينها بفاصلة. تساعد في البحث وتمنع تكرار نفس المنطقة.">
          <Input value={form.aliases} onChange={(e) => setForm({ ...form, aliases: e.target.value })} placeholder="Rashid Suburb، الرشيد" />
        </Field>
        <Field label="ملاحظات داخلية" optional>
          <Textarea value={form.notes} onChange={(e) => setForm({ ...form, notes: e.target.value })} />
        </Field>
      </div>
    </Dialog>
  );
}
