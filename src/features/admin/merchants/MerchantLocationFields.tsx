import { useState } from 'react';
import { Info, MapPin } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { pickupLocationError, isUnchangedLegacyLocation } from '@/application/merchantLocation';
import type { LatLng, Merchant } from '@/domain/types';
import { cityName } from '@/domain/cities';
import { polygonCentroid } from '@/domain/geo';
import { Field, FormRow, FormSection } from '@/shared/components/ui';
import { LocationSearchField } from '@/features/merchant/location/LocationSearchField';
import { LocationPicker } from '../LocationPicker';
import { AreaSelect } from '../service-areas/AreaSelect';
import { CitySelect } from '../service-areas/CitySelect';

export interface PickupValue {
  cityId: string | null;
  areaId: string | null;
  pickup: LatLng | null;
}

/**
 * City → Area → pickup location (owner, 2026-11-25): the location is chosen by tapping the map or by
 * picking a search result (shop name, area or address, anywhere — not limited to Amman or to priced
 * zones). No draggable pin. Changing City clears the Area and location; the Area is never derived
 * from the coordinate.
 */
export function MerchantLocationFields({ value, existing, error, onChange }: { value: PickupValue; existing?: Merchant; error?: string; onChange: (patch: Partial<PickupValue>) => void }) {
  const areas = useAppStore((s) => s.areas);
  const [focus, setFocus] = useState<LatLng | null>(null);
  const [placeName, setPlaceName] = useState<string | null>(null);
  const area = areas.find((a) => a.id === value.areaId);
  const legacy = !!existing && !existing.areaId;
  const liveError =
    value.pickup && area && !(legacy && isUnchangedLegacyLocation(existing, { ...value, pickup: value.pickup }))
      ? pickupLocationError(areas, { ...value, pickup: value.pickup })
      : null;

  return (
    <FormSection title="موقع المتجر / الاستلام">
      {legacy && (
        <p className="flex items-start gap-1.5 rounded-lg bg-amber-50 p-3 text-xs text-amber-900">
          <Info className="mt-0.5 h-4 w-4 shrink-0" aria-hidden /> سجل قديم بعنوان نصي: «{existing.address}». يبقى كما هو إلى أن تختار المدينة والمنطقة.
        </p>
      )}
      <FormRow>
        <Field label="المدينة" required={!legacy} htmlFor="merchant-city">
          <CitySelect
            id="merchant-city"
            value={value.cityId ?? ''}
            onChange={(e) => { setFocus(null); setPlaceName(null); onChange({ cityId: e.target.value || null, areaId: null, pickup: null }); }}
          />
        </Field>
        <Field label="المنطقة" required={!legacy} htmlFor="merchant-area">
          <AreaSelect
            id="merchant-area"
            areas={areas}
            scope={{ by: 'city', id: value.cityId ?? '' }}
            placeholder="اختر المنطقة"
            value={value.areaId ?? ''}
            onChange={(e) => {
              const next = areas.find((a) => a.id === e.target.value);
              if (next && next.polygon.length >= 3 && !value.pickup) setFocus(polygonCentroid(next.polygon));
              onChange({ areaId: e.target.value || null });
            }}
          />
        </Field>
      </FormRow>
      <Field
        label="موقع المتجر على الخريطة"
        required={!legacy}
        error={error || liveError || undefined}
        hint="اضغط على مكان المتجر في الخريطة أو ابحث عنه. يمكن التسجيل في أي موقع؛ مناطق التوصيل تُفعَّل من «أسعار التجار»."
      >
        <div className="space-y-2" data-invalid={!!(error || liveError)} tabIndex={error || liveError ? -1 : undefined}>
          <LocationSearchField
            label="ابحث باسم المتجر أو المنطقة أو العنوان"
            placeholder="ابحث باسم المتجر أو المنطقة أو العنوان"
            bounded={false}
            onSelect={(p) => { setPlaceName([p.name, p.context].filter(Boolean).join('، ')); onChange({ pickup: p.position }); }}
          />
          <LocationPicker value={value.pickup} focus={focus} boundary={area?.polygon} onChange={(p) => { setPlaceName(null); onChange({ pickup: p }); }} />
          {value.pickup && (
            <p className="flex flex-wrap items-center gap-x-2 gap-y-1 rounded-lg bg-cream px-3 py-2 text-sm" aria-live="polite">
              <MapPin className="h-4 w-4 shrink-0 text-primary" aria-hidden />
              <span>الموقع المحدد: <b>{placeName ?? (area ? `${area.name}، ${cityName(value.cityId)}` : 'نقطة على الخريطة')}</b></span>
              <span dir="ltr" className="text-xs text-ink-muted">{value.pickup.lat.toFixed(5)}, {value.pickup.lng.toFixed(5)}</span>
            </p>
          )}
        </div>
      </Field>
    </FormSection>
  );
}
