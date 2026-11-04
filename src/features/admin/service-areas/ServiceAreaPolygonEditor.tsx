import { useState } from 'react';
import { Marker, Polygon, Polyline, Tooltip } from 'react-leaflet';
import { Check, Undo2, X } from 'lucide-react';
import { useAppStore } from '@/application/store';
import type { LatLng, ServiceArea } from '@/domain/types';
import { Button } from '@/shared/components/ui';
import { BaseMap, FitBounds, MapClickHandler } from '@/shared/components/map/BaseMap';
import { vertexIcon } from '@/shared/components/map/markers';
import { reportResult } from '@/shared/components/toast';
import { cn } from '@/shared/lib/cn';

const toLatLngs = (ps: LatLng[]) => ps.map((p) => [p.lat, p.lng] as [number, number]);

/**
 * Zone boundaries on the map, and drawing a new boundary for `drawing`. The polygons
 * are what customer pins are matched against (point-in-polygon), so they stay editable.
 */
export function ServiceAreaPolygonEditor({ areas, drawing, onDone }: { areas: ServiceArea[]; drawing: ServiceArea | null; onDone: () => void }) {
  const updateZone = useAppStore((s) => s.updateZone);
  const [points, setPoints] = useState<LatLng[]>([]);
  const [lastId, setLastId] = useState<string | null>(null);
  if ((drawing?.id ?? null) !== lastId) {
    setLastId(drawing?.id ?? null);
    setPoints([]);
  }

  const finish = () => {
    if (drawing && reportResult(updateZone(drawing.id, { polygon: points }), 'تم حفظ حدود المنطقة على الخريطة')) onDone();
  };

  return (
    <div className="relative">
      <BaseMap className={cn('h-[460px]', drawing && 'ring-4 ring-primary-200')} label="حدود مناطق التوصيل">
        <FitBounds points={areas.flatMap((a) => a.polygon)} fitKey={areas.map((a) => a.id).join()} maxZoom={13} />
        {drawing && <MapClickHandler onClick={(p) => setPoints((ps) => [...ps, p])} />}
        {areas
          .filter((a) => a.polygon.length >= 3)
          .map((a) => (
            <Polygon
              key={a.id}
              positions={toLatLngs(a.polygon)}
              pathOptions={{ color: a.status === 'active' ? '#263D34' : '#8A8580', weight: 2, dashArray: a.status === 'active' ? undefined : '6 6', fillOpacity: 0.12 }}
              interactive={!drawing}
            >
              <Tooltip permanent direction="center" className="!border-0 !bg-white/90 !text-xs !font-bold !shadow">{a.name}</Tooltip>
            </Polygon>
          ))}
        {drawing && points.length > 0 && (
          <>
            {points.length >= 3 ? (
              <Polygon positions={toLatLngs(points)} pathOptions={{ color: '#8C2335', weight: 2, fillOpacity: 0.2 }} />
            ) : (
              <Polyline positions={toLatLngs(points)} pathOptions={{ color: '#8C2335', weight: 2 }} />
            )}
            {points.map((p, i) => <Marker key={i} position={[p.lat, p.lng]} icon={vertexIcon()} />)}
          </>
        )}
      </BaseMap>
      {drawing && (
        <div className="absolute inset-x-3 top-3 z-[500] rounded-2xl bg-white p-3 shadow-pop">
          <p className="text-sm font-bold">رسم حدود «{drawing.name}» — اضغط على الخريطة ({points.length} نقاط)</p>
          <div className="mt-2 flex flex-wrap gap-2">
            <Button size="sm" icon={<Check className="h-4 w-4" />} onClick={finish} disabled={points.length < 3}>حفظ</Button>
            <Button size="sm" variant="outline" icon={<Undo2 className="h-4 w-4" />} onClick={() => setPoints((ps) => ps.slice(0, -1))} disabled={!points.length}>تراجع</Button>
            <Button size="sm" variant="ghost" icon={<X className="h-4 w-4" />} onClick={onDone}>إلغاء</Button>
          </div>
        </div>
      )}
    </div>
  );
}
