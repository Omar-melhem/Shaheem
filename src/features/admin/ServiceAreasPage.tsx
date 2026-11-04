import { useState } from 'react';
import { Marker, Polygon, Polyline, Tooltip } from 'react-leaflet';
import { Check, Pencil, PenTool, Plus, Shapes, Undo2, X } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { LatLng } from '@/domain/types';
import { polygonCentroid } from '@/domain/geo';
import { Badge, Button, Card, ConfirmDialog, EmptyState, Field, Input, OpenDecision, PageHeader, Toggle } from '@/shared/components/ui';
import { BaseMap, FitBounds, MapClickHandler } from '@/shared/components/map/BaseMap';
import { vertexIcon } from '@/shared/components/map/markers';
import { reportResult } from '@/shared/components/toast';
import { formatDate } from '@/shared/lib/format';
import { cn } from '@/shared/lib/cn';

type Mode = { kind: 'view' } | { kind: 'draw'; areaId?: string };

/** Admin draws service-area polygons on the map (SRS §7.1). */
export function ServiceAreasPage() {
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const orders = useAppStore((s) => s.orders);
  const createServiceArea = useAppStore((s) => s.createServiceArea);
  const updateServiceArea = useAppStore((s) => s.updateServiceArea);
  const setServiceAreaStatus = useAppStore((s) => s.setServiceAreaStatus);

  const [mode, setMode] = useState<Mode>({ kind: 'view' });
  const [points, setPoints] = useState<LatLng[]>([]);
  const [name, setName] = useState('');
  const [selected, setSelected] = useState<string | null>(null);
  const [renaming, setRenaming] = useState<{ id: string; name: string } | null>(null);
  const [toggleTarget, setToggleTarget] = useState<string | null>(null);

  const drawing = mode.kind === 'draw';
  const startDraw = (areaId?: string) => {
    setMode({ kind: 'draw', areaId });
    setPoints([]);
    setName(areaId ? areas.find((a) => a.id === areaId)?.name ?? '' : '');
  };
  const cancelDraw = () => {
    setMode({ kind: 'view' });
    setPoints([]);
  };
  const finishDraw = () => {
    if (mode.kind !== 'draw') return;
    const result = mode.areaId ? updateServiceArea(mode.areaId, { polygon: points }) : createServiceArea(name, points);
    if (reportResult(result, mode.areaId ? 'تم تحديث حدود المنطقة' : 'تم إنشاء منطقة الخدمة')) cancelDraw();
  };

  const toggleArea = areas.find((a) => a.id === toggleTarget);

  return (
    <>
      <PageHeader
        title="مناطق الخدمة"
        description="ارسم حدود كل منطقة كمضلّع على الخريطة. يُحدَّد سعر التوصيل بمطابقة إحداثيات وجهة العميل مع المضلّع الذي يحتويها."
        actions={!drawing && <Button icon={<Plus className="h-4 w-4" />} onClick={() => startDraw()}>منطقة جديدة</Button>}
      />

      <div className="grid gap-4 xl:grid-cols-[1fr_360px]">
        <div className="relative">
          <BaseMap className={cn('h-[64vh] min-h-[420px]', drawing && 'ring-4 ring-primary-200')} label="خريطة مناطق الخدمة">
            <FitBounds points={areas.flatMap((a) => a.polygon)} fitKey="areas" maxZoom={13} />
            {drawing && <MapClickHandler onClick={(p) => setPoints((ps) => [...ps, p])} />}
            {areas.map((a) => (
              <Polygon
                key={a.id}
                positions={a.polygon.map((p) => [p.lat, p.lng] as [number, number])}
                pathOptions={{
                  color: a.status === 'active' ? (selected === a.id ? '#8C2335' : '#263D34') : '#8A8580',
                  weight: selected === a.id ? 3 : 2,
                  dashArray: a.status === 'active' ? undefined : '6 6',
                  fillOpacity: selected === a.id ? 0.25 : 0.12,
                }}
                eventHandlers={{ click: () => !drawing && setSelected(a.id) }}
                interactive={!drawing}
              >
                <Tooltip permanent direction="center" className="!border-0 !bg-white/90 !text-xs !font-bold !shadow">{a.name}</Tooltip>
              </Polygon>
            ))}
            {drawing && points.length > 0 && (
              <>
                {points.length >= 3 ? (
                  <Polygon positions={points.map((p) => [p.lat, p.lng] as [number, number])} pathOptions={{ color: '#8C2335', weight: 2, fillOpacity: 0.2 }} />
                ) : (
                  <Polyline positions={points.map((p) => [p.lat, p.lng] as [number, number])} pathOptions={{ color: '#8C2335', weight: 2 }} />
                )}
                {points.map((p, i) => (
                  <Marker key={i} position={[p.lat, p.lng]} icon={vertexIcon()} />
                ))}
              </>
            )}
          </BaseMap>
          {drawing && (
            <div className="absolute inset-x-4 top-4 z-[500] mx-auto max-w-xl rounded-2xl bg-white p-4 shadow-pop">
              <p className="flex items-center gap-2 text-sm font-bold">
                <PenTool className="h-4 w-4 text-primary" />
                {mode.kind === 'draw' && mode.areaId ? 'إعادة رسم الحدود' : 'رسم منطقة جديدة'} — اضغط على الخريطة لإضافة نقاط ({points.length})
              </p>
              {mode.kind === 'draw' && !mode.areaId && (
                <Field label="اسم المنطقة" required className="mt-3">
                  <Input value={name} onChange={(e) => setName(e.target.value)} placeholder="مثال: ضاحية الرشيد" />
                </Field>
              )}
              <div className="mt-3 flex flex-wrap gap-2">
                <Button size="sm" icon={<Check className="h-4 w-4" />} onClick={finishDraw} disabled={points.length < 3}>حفظ المنطقة</Button>
                <Button size="sm" variant="outline" icon={<Undo2 className="h-4 w-4" />} onClick={() => setPoints((ps) => ps.slice(0, -1))} disabled={!points.length}>تراجع عن نقطة</Button>
                <Button size="sm" variant="ghost" icon={<X className="h-4 w-4" />} onClick={cancelDraw}>إلغاء</Button>
              </div>
            </div>
          )}
        </div>

        <div className="space-y-4">
          <Card>
            {areas.length === 0 ? (
              <EmptyState icon={<Shapes className="h-6 w-6" />} title="لا توجد مناطق" description="ابدأ برسم أول منطقة خدمة." />
            ) : (
              <ul className="divide-y divide-cream-dark">
                {areas.map((a) => {
                  const priced = prices.filter((p) => p.areaId === a.id).length;
                  const orderCount = orders.filter((o) => o.areaId === a.id).length;
                  return (
                    <li key={a.id} className={cn('space-y-2 px-4 py-3', selected === a.id && 'bg-primary-50/60')}>
                      <div className="flex items-center justify-between gap-2">
                        {renaming?.id === a.id ? (
                          <form
                            className="flex flex-1 gap-2"
                            onSubmit={(e) => {
                              e.preventDefault();
                              if (reportResult(updateServiceArea(a.id, { name: renaming.name }), 'تم تغيير اسم المنطقة')) setRenaming(null);
                            }}
                          >
                            <Input value={renaming.name} onChange={(e) => setRenaming({ id: a.id, name: e.target.value })} className="h-8" autoFocus aria-label="اسم المنطقة" />
                            <Button size="sm" type="submit">حفظ</Button>
                          </form>
                        ) : (
                          <button className="font-bold hover:text-primary" onClick={() => setSelected(a.id)}>{a.name}</button>
                        )}
                        <Badge tone={a.status === 'active' ? 'success' : 'neutral'}>{a.status === 'active' ? 'نشطة' : 'متوقفة'}</Badge>
                      </div>
                      <p className="text-xs text-ink-muted">
                        {a.polygon.length} نقاط · {priced} تاجر مسعّر · {orderCount} طلب · حُدّثت {formatDate(a.updatedAt)}
                      </p>
                      {!drawing && (
                        <div className="flex flex-wrap gap-1">
                          <Button size="sm" variant="ghost" icon={<Pencil className="h-3.5 w-3.5" />} onClick={() => setRenaming({ id: a.id, name: a.name })}>الاسم</Button>
                          <Button size="sm" variant="ghost" icon={<PenTool className="h-3.5 w-3.5" />} onClick={() => { setSelected(a.id); startDraw(a.id); }}>الحدود</Button>
                          <div className="ms-auto">
                            <Toggle checked={a.status === 'active'} onChange={() => setToggleTarget(a.id)} label={<span className="sr-only">تفعيل المنطقة</span>} />
                          </div>
                        </div>
                      )}
                    </li>
                  );
                })}
              </ul>
            )}
          </Card>
          <OpenDecision id="O-011">هل المناطق مشتركة بين كل التجار (بأسعار مختلفة) أم لكل تاجر مضلّعاته؟ هذا النموذج يستخدم مناطق مشتركة.</OpenDecision>
          <OpenDecision id="O-012 / O-013">تداخل المضلّعات والنقاط على الحدود غير محسومة؛ عند التداخل يُمنع الطلب ويُعرض السبب.</OpenDecision>
          <p className="text-xs text-ink-muted">تعديل الحدود أو الاسم لا يغيّر الطلبات السابقة — كل طلب يحتفظ بلقطة من المنطقة والسعر. مركز المنطقة المحددة: {selected && areas.find((a) => a.id === selected) ? (() => { const c = polygonCentroid(areas.find((a) => a.id === selected)!.polygon); return <span dir="ltr">{c.lat.toFixed(4)}, {c.lng.toFixed(4)}</span>; })() : '—'}</p>
        </div>
      </div>

      <ConfirmDialog
        open={!!toggleArea}
        onClose={() => setToggleTarget(null)}
        onConfirm={() => toggleArea && reportResult(setServiceAreaStatus(toggleArea.id, toggleArea.status !== 'active'), 'تم تحديث حالة المنطقة')}
        title={toggleArea?.status === 'active' ? `إيقاف منطقة ${toggleArea?.name}؟` : `تفعيل منطقة ${toggleArea?.name}؟`}
        description={toggleArea?.status === 'active' ? 'لن تُقبل طلبات جديدة لوجهات داخل هذه المنطقة. الطلبات القائمة لا تتأثر.' : 'ستعود المنطقة لتحديد الأسعار للطلبات الجديدة.'}
        variant={toggleArea?.status === 'active' ? 'danger' : 'secondary'}
      />
    </>
  );
}
