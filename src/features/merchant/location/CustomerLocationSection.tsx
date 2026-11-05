import { useState } from 'react';
import { AlertTriangle, CheckCircle2, Info } from 'lucide-react';
import type { LocationFeeResolution } from '@/application/queries';
import type { LatLng, ServiceArea } from '@/domain/types';
import { polygonCentroid } from '@/domain/geo';
import { Field, OpenDecision } from '@/shared/components/ui';
import { LocationSearchField } from './LocationSearchField';
import { DestinationMapPicker } from './DestinationMapPicker';

export interface CustomerLocation {
  position: LatLng;
  placeName?: string;
}

export const OUTSIDE_MSG = 'هذا الموقع خارج مناطق التوصيل المفعّلة لحسابك. حرّك الدبوس أو تواصل مع إدارة شهم.';
export const UNAVAILABLE_MSG = 'التوصيل إلى هذه المنطقة غير متاح حالياً. يرجى التواصل مع إدارة شهم.';

/**
 * Searchable destination list + map pin. Only a pin produces coordinates: choosing an area
 * moves the map and asks for a precise tap, and the zone and fee always come from the pin.
 */
export function CustomerLocationSection({
  value,
  pickup,
  areas,
  resolution,
  error,
  onChange,
}: {
  value: CustomerLocation | null;
  pickup: LatLng;
  /** The Merchant's enabled zones that have a boundary. */
  areas: ServiceArea[];
  resolution: LocationFeeResolution | null;
  error?: string;
  onChange: (loc: CustomerLocation | null) => void;
}) {
  const [focusedArea, setFocusedArea] = useState<ServiceArea | null>(null);

  const chooseArea = (area: ServiceArea) => {
    setFocusedArea(area);
    onChange(null); // a pin from elsewhere no longer matches what the Merchant just chose
  };

  return (
    <Field label="موقع العميل" required error={error}>
      <div className="space-y-2">
        <LocationSearchField
          label="ابحث عن منطقة أو موقع العميل"
          placeholder="ابحث عن منطقة أو موقع العميل"
          invalid={!!error}
          areas={areas}
          onSelectArea={chooseArea}
          onSelect={(p) => { setFocusedArea(null); onChange({ position: p.position, placeName: p.name }); }}
        />
        <DestinationMapPicker
          value={value?.position ?? null}
          pickup={pickup}
          focus={focusedArea ? polygonCentroid(focusedArea.polygon) : null}
          onChange={(position) => onChange({ position, placeName: undefined })}
        />
        {!value && focusedArea && (
          <p className="flex items-start gap-1.5 text-sm font-medium text-amber-800" role="status">
            <Info className="mt-0.5 h-4 w-4 shrink-0" aria-hidden /> اخترت «{focusedArea.name}». اضغط على الخريطة لتحديد موقع العميل بدقة — اسم المنطقة وحده لا يكفي للكابتن.
          </p>
        )}
        {!value && !focusedArea && <p className="text-xs text-ink-muted">ابحث عن المكان أو اضغط على الخريطة، ثم اسحب الدبوس لضبط الموقع بدقة.</p>}
        {resolution?.kind === 'ok' && (
          <p className="flex items-center gap-1.5 text-sm font-medium text-secondary" aria-live="polite">
            <CheckCircle2 className="h-4 w-4" /> المنطقة: {resolution.area.name}
            {value?.placeName && <span className="text-ink-muted">· {value.placeName}</span>}
          </p>
        )}
        {resolution && resolution.kind !== 'ok' && (
          <p className="flex items-start gap-1.5 text-sm font-medium text-red-700" role="alert">
            <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" /> {resolution.kind === 'outside' ? OUTSIDE_MSG : UNAVAILABLE_MSG}
          </p>
        )}
        <OpenDecision id="O-018">البحث من OpenStreetMap للعرض؛ مزوّد الخرائط والبحث النهائي لم يُعتمد بعد.</OpenDecision>
      </div>
    </Field>
  );
}
