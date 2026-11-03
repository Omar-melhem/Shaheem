import { useEffect } from 'react';
import { Marker, useMap } from 'react-leaflet';
import type { LatLng } from '@/domain/types';
import { BaseMap, InvalidateSize, MapClickHandler } from '@/shared/components/map/BaseMap';
import { destinationIcon, merchantIcon } from '@/shared/components/map/markers';

/** Moves the view to the pin whenever it changes (e.g. after a search pick). */
function FollowPin({ pin }: { pin: LatLng | null }) {
  const map = useMap();
  useEffect(() => {
    if (pin) map.setView([pin.lat, pin.lng], Math.max(map.getZoom(), 16), { animate: true });
  }, [pin, map]);
  return null;
}

/** Customer pin: tap the map or drag the pin to adjust, like a delivery app. Shows the pickup for reference. */
export function DestinationMapPicker({ value, pickup, onChange }: { value: LatLng | null; pickup: LatLng; onChange: (p: LatLng) => void }) {
  return (
    <BaseMap className="h-60" center={value ?? pickup} zoom={value ? 16 : 13} label="حدّد موقع العميل على الخريطة">
      <InvalidateSize />
      <MapClickHandler onClick={onChange} />
      <FollowPin pin={value} />
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
