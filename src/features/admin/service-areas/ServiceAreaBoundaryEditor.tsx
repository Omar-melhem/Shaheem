import { useState } from 'react';
import { Marker, Polygon, Polyline, Tooltip } from 'react-leaflet';
import { Check, Trash2, Undo2 } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { LatLng, ServiceArea } from '@/domain/types';
import { polygonError } from '@/domain/geo';
import { Button, ConfirmDialog, Dialog } from '@/shared/components/ui';
import { BaseMap, FitBounds, InvalidateSize, MapClickHandler } from '@/shared/components/map/BaseMap';
import { vertexIcon } from '@/shared/components/map/markers';
import { reportResult } from '@/shared/components/toast';

const toLatLngs = (ps: LatLng[]) => ps.map((p) => [p.lat, p.lng] as [number, number]);

/**
 * Focused boundary editor for one Area (CR v1.3 §5.2), opened only from «تعديل الحدود» or the
 * From-Area step. Loads the saved polygon; tap adds a vertex, drag moves one. Nothing is written
 * until «حفظ الحدود», and only to this Area. Customer pins are matched against these polygons.
 */
export function ServiceAreaBoundaryEditor({ area, onClose }: { area: ServiceArea | null; onClose: () => void }) {
  const areas = useAppStore((s) => s.areas);
  const updateZone = useAppStore((s) => s.updateZone);
  const [points, setPoints] = useState<LatLng[]>([]);
  const [lastId, setLastId] = useState<string | null>(null);
  const [confirmDiscard, setConfirmDiscard] = useState(false);

  const id = area?.id ?? null;
  if (id !== lastId) {
    setLastId(id);
    setPoints(area?.polygon ?? []);
  }
  if (!area) return null;

  const dirty = JSON.stringify(points) !== JSON.stringify(area.polygon);
  const geometryError = points.length > 0 ? polygonError(points) : null;
  const canSave = dirty && points.length >= 3 && !geometryError;
  const others = areas.filter((a) => a.id !== area.id && a.polygon.length >= 3);
  const moveVertex = (index: number, next: LatLng) => setPoints((ps) => ps.map((p, i) => (i === index ? next : p)));

  const requestClose = () => {
    if (dirty) setConfirmDiscard(true);
    else onClose();
  };
  const save = () => {
    if (reportResult(updateZone(area.id, { polygon: points }), `تم حفظ حدود «${area.name}»`)) onClose();
  };

  return (
    <>
      <Dialog
        open
        onClose={requestClose}
        size="xl"
        title={`تعديل حدود «${area.name}»`}
        description="اضغط على الخريطة لإضافة نقطة، واسحب أي نقطة لتحريكها."
        footer={
          <>
            <Button variant="ghost" icon={<Undo2 className="h-4 w-4" />} disabled={points.length === 0} onClick={() => setPoints((ps) => ps.slice(0, -1))}>تراجع</Button>
            <Button variant="ghost" icon={<Trash2 className="h-4 w-4" />} disabled={points.length === 0} onClick={() => setPoints([])}>مسح النقاط</Button>
            <Button variant="outline" onClick={requestClose}>إلغاء</Button>
            <Button icon={<Check className="h-4 w-4" />} disabled={!canSave} onClick={save}>حفظ الحدود</Button>
          </>
        }
      >
        <div className="space-y-2">
          <BaseMap className="h-[52vh] min-h-[320px] ring-2 ring-primary-200" label={`حدود ${area.name}`}>
            <InvalidateSize />
            <FitBounds points={area.polygon.length >= 3 ? area.polygon : others.flatMap((a) => a.polygon)} fitKey={area.id} maxZoom={14} />
            <MapClickHandler onClick={(p) => setPoints((ps) => [...ps, p])} />
            {others.map((a) => (
              <Polygon key={a.id} positions={toLatLngs(a.polygon)} interactive={false} pathOptions={{ color: '#8A8580', weight: 1, dashArray: '4 4', fillOpacity: 0.04 }}>
                <Tooltip permanent direction="center" className="!border-0 !bg-white/70 !text-[11px] !shadow-none">{a.name}</Tooltip>
              </Polygon>
            ))}
            {points.length >= 3 ? (
              <Polygon positions={toLatLngs(points)} interactive={false} pathOptions={{ color: '#8C2335', weight: 2, fillOpacity: 0.2 }} />
            ) : (
              points.length > 1 && <Polyline positions={toLatLngs(points)} interactive={false} pathOptions={{ color: '#8C2335', weight: 2 }} />
            )}
            {points.map((p, i) => (
              <Marker
                key={i}
                position={[p.lat, p.lng]}
                icon={vertexIcon()}
                draggable
                eventHandlers={{ dragend: (e) => { const ll = e.target.getLatLng(); moveVertex(i, { lat: ll.lat, lng: ll.lng }); } }}
              />
            ))}
          </BaseMap>
          <p className={geometryError ? 'text-sm font-medium text-red-700' : 'text-xs text-ink-muted'} role={geometryError ? 'alert' : undefined}>
            {geometryError ?? `${points.length} نقاط. المناطق الأخرى ظاهرة للمرجع فقط؛ التداخل بين المناطق لا يُعالج تلقائياً.`}
          </p>
        </div>
      </Dialog>
      <ConfirmDialog
        open={confirmDiscard}
        onClose={() => setConfirmDiscard(false)}
        onConfirm={onClose}
        title="تجاهل التعديلات؟"
        description="لن تُحفظ التعديلات على هذه الحدود."
        confirmLabel="تجاهل"
        variant="danger"
      />
    </>
  );
}
