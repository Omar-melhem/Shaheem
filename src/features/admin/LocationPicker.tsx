import { useEffect } from 'react';
import { Marker, Polygon, useMap } from 'react-leaflet';
import type { LatLng } from '@/domain/types';
import { BaseMap, MapClickHandler, InvalidateSize } from '@/shared/components/map/BaseMap';
import { merchantIcon } from '@/shared/components/map/markers';

function MoveTo({ point }: { point: LatLng | null | undefined }) {
  const map = useMap();
  useEffect(() => {
    if (point) map.setView([point.lat, point.lng], Math.max(map.getZoom(), 14), { animate: true });
  }, [point, map]);
  return null;
}

/**
 * Merchant pickup location (owner, 2026-11-25): set by tapping the map (or by a search result in the
 * form). The marker only shows the choice — it is not draggable. `focus` moves the map without
 * choosing a location; `boundary` outlines the selected Area for reference only.
 */
export function LocationPicker({ value, onChange, focus, boundary }: { value: LatLng | null; onChange: (p: LatLng) => void; focus?: LatLng | null; boundary?: LatLng[] }) {
  return (
    <div className="space-y-1">
      <BaseMap className="h-64" center={value ?? undefined} zoom={value ? 15 : 12} label="تحديد موقع المتجر على الخريطة">
        <InvalidateSize />
        <MapClickHandler onClick={onChange} />
        <MoveTo point={focus} />
        <MoveTo point={value} />
        {boundary && boundary.length >= 3 && (
          <Polygon positions={boundary.map((p) => [p.lat, p.lng] as [number, number])} interactive={false} pathOptions={{ color: '#263D34', weight: 2, fillOpacity: 0.08 }} />
        )}
        {value && (
          <Marker position={[value.lat, value.lng]} icon={merchantIcon()} interactive={false} keyboard={false} title="موقع الاستلام المحدد" />
        )}
      </BaseMap>
      {!value && <p className="text-xs text-ink-muted">اضغط على مكان المتجر في الخريطة، أو ابحث عنه بالاسم أو العنوان.</p>}
    </div>
  );
}
