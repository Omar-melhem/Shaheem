import { useEffect } from 'react';
import { Marker, Polygon, useMap } from 'react-leaflet';
import { hasAreaBoundary } from '@/domain/destination';
import type { LatLng, ServiceArea } from '@/domain/types';
import { BaseMap, FitBounds, InvalidateSize, MapClickHandler } from '@/shared/components/map/BaseMap';
import { destinationIcon, merchantIcon } from '@/shared/components/map/markers';

/** Moves the view when the pin changes (a search pick or a map tap). */
function FollowPoint({ point, zoom }: { point: LatLng | null; zoom: number }) {
  const map = useMap();
  useEffect(() => {
    if (point) map.setView([point.lat, point.lng], Math.max(map.getZoom(), zoom), { animate: true });
  }, [point, zoom, map]);
  return null;
}

/**
 * Shows the chosen delivery area's boundary and frames it; no pin is ever placed for the
 * Merchant. Inside an area with a boundary, tapping the map or dragging the pin sets the
 * optional exact location. Shows the pickup for reference.
 */
export function DestinationMapPicker({ value, pickup, area, onChange }: { value: LatLng | null; pickup: LatLng; area: ServiceArea | null; onChange: (p: LatLng) => void }) {
  const boundary = area && hasAreaBoundary(area) ? area.polygon : null;
  return (
    <BaseMap className="h-[220px] sm:h-[260px]" center={value ?? pickup} zoom={value ? 16 : 13} label="خريطة منطقة التوصيل">
      <InvalidateSize />
      {boundary && (
        <>
          <MapClickHandler onClick={onChange} />
          <Polygon positions={boundary.map((p) => [p.lat, p.lng] as [number, number])} interactive={false} pathOptions={{ color: '#8C2335', weight: 2, fillOpacity: 0.12 }} />
          <FitBounds points={boundary} fitKey={area!.id} />
        </>
      )}
      <FollowPoint point={value} zoom={16} />
      <Marker position={[pickup.lat, pickup.lng]} icon={merchantIcon()} interactive={false} title="موقع الاستلام" />
      {value && (
        <Marker
          position={[value.lat, value.lng]}
          icon={destinationIcon()}
          draggable
          title="موقع العميل — اسحبه لتعديل الموقع"
          eventHandlers={{
            dragend: (e) => {
              const ll = e.target.getLatLng();
              onChange({ lat: ll.lat, lng: ll.lng });
            },
          }}
        />
      )}
    </BaseMap>
  );
}
