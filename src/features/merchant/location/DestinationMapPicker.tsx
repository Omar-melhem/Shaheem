import { useEffect } from 'react';
import { Marker, useMap } from 'react-leaflet';
import type { LatLng } from '@/domain/types';
import { BaseMap, InvalidateSize, MapClickHandler } from '@/shared/components/map/BaseMap';
import { destinationIcon, merchantIcon } from '@/shared/components/map/markers';

/** Moves the view when the target changes (a search pick, or an area chosen from the list). */
function FollowPoint({ point, zoom }: { point: LatLng | null; zoom: number }) {
  const map = useMap();
  useEffect(() => {
    if (point) map.setView([point.lat, point.lng], Math.max(map.getZoom(), zoom), { animate: true });
  }, [point, zoom, map]);
  return null;
}

/**
 * Customer pin: tap the map or drag the pin to adjust, like a delivery app. Shows the
 * pickup for reference. `focus` moves the map without placing a pin.
 */
export function DestinationMapPicker({ value, pickup, focus, onChange }: { value: LatLng | null; pickup: LatLng; focus?: LatLng | null; onChange: (p: LatLng) => void }) {
  return (
    <BaseMap className="h-60" center={value ?? pickup} zoom={value ? 16 : 13} label="حدّد موقع العميل على الخريطة">
      <InvalidateSize />
      <MapClickHandler onClick={onChange} />
      <FollowPoint point={focus ?? null} zoom={14} />
      <FollowPoint point={value} zoom={16} />
      <Marker position={[pickup.lat, pickup.lng]} icon={merchantIcon()} interactive={false} />
      {value && (
        <Marker
          position={[value.lat, value.lng]}
          icon={destinationIcon()}
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
  );
}
