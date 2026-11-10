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
 * Pickup pin for Merchant profiles: tap to place, drag to adjust. `focus` moves the map
 * without placing a pin; `boundary` outlines the selected Area for reference.
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
          <Marker
            position={[value.lat, value.lng]}
            icon={merchantIcon()}
            draggable
            eventHandlers={{
              dragend: (e) => {
                const ll = e.target.getLatLng();
                onChange({ lat: ll.lat, lng: ll.lng });
              },
            }}
          />
        )}
      </BaseMap>
      <p className="text-xs text-ink-muted" dir="ltr" style={{ textAlign: 'right' }}>
        {value ? `${value.lat.toFixed(5)}, ${value.lng.toFixed(5)}` : 'اضغط على الخريطة لتحديد الموقع'}
      </p>
    </div>
  );
}
