import { AlertTriangle, CheckCircle2 } from 'lucide-react';
import type { LocationFeeResolution } from '@/application/queries';
import type { LatLng } from '@/domain/types';
import { Field, OpenDecision } from '@/shared/components/ui';
import { LocationSearchField } from './LocationSearchField';
import { DestinationMapPicker } from './DestinationMapPicker';

export interface CustomerLocation {
  position: LatLng;
  placeName?: string;
}

export const OUTSIDE_MSG = 'هذا الموقع خارج مناطق التوصيل المفعّلة لحسابك. حرّك الدبوس أو تواصل مع إدارة شهم.';
export const UNAVAILABLE_MSG = 'التوصيل إلى هذه المنطقة غير متاح حالياً. يرجى التواصل مع إدارة شهم.';

/** Search + map pin for the customer's location, with the detected zone shown underneath. */
export function CustomerLocationSection({
  value,
  pickup,
  resolution,
  error,
  onChange,
}: {
  value: CustomerLocation | null;
  pickup: LatLng;
  resolution: LocationFeeResolution | null;
  error?: string;
  onChange: (loc: CustomerLocation) => void;
}) {
  return (
    <Field label="موقع العميل" required error={error}>
      <div className="space-y-2">
        <LocationSearchField invalid={!!error} onSelect={(p) => onChange({ position: p.position, placeName: p.name })} />
        <DestinationMapPicker value={value?.position ?? null} pickup={pickup} onChange={(position) => onChange({ position, placeName: undefined })} />
        {!value && <p className="text-xs text-ink-muted">ابحث عن المكان أو اضغط على الخريطة، ثم اسحب الدبوس لضبط الموقع بدقة.</p>}
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
