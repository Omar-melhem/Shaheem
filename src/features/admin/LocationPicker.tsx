import { Marker } from 'react-leaflet';
import type { LatLng } from '@/domain/types';
import { BaseMap, MapClickHandler, InvalidateSize } from '@/shared/components/map/BaseMap';
import { merchantIcon } from '@/shared/components/map/markers';

/** Click-to-place pickup location picker for Merchant profiles. */
export function LocationPicker({ value, onChange }: { value: LatLng | null; onChange: (p: LatLng) => void }) {
  return (
    <div className="space-y-1">
      <BaseMap className="h-64" center={value ?? undefined} zoom={value ? 15 : 12} label="اختر موقع الاستلام">
        <InvalidateSize />
        <MapClickHandler onClick={onChange} />
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
