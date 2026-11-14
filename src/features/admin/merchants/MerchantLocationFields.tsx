import { useState } from 'react';
import { AlertTriangle, Info } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { pickupLocationError, isUnchangedLegacyLocation } from '@/application/merchantLocation';
import type { LatLng, Merchant } from '@/domain/types';
import { cityName } from '@/domain/cities';
import { polygonCentroid } from '@/domain/geo';
import { Field, OpenDecision } from '@/shared/components/ui';
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
 * City → Area → exact pickup pin (CR v1.3 §3). Changing City clears the Area and pin; changing
 * Area keeps the pin but re-checks it against the Area's boundary and never reassigns it.
 */
export function MerchantLocationFields({ value, existing, error, onChange }: { value: PickupValue; existing?: Merchant; error?: string; onChange: (patch: Partial<PickupValue>) => void }) {
  const areas = useAppStore((s) => s.areas);
  const [focus, setFocus] = useState<LatLng | null>(null);
  const area = areas.find((a) => a.id === value.areaId);
  const hasBoundary = !!area && area.polygon.length >= 3;
  const legacy = !!existing && !existing.areaId;
  const liveError =
    value.pickup && area && !(legacy && isUnchangedLegacyLocation(existing, { ...value, pickup: value.pickup }))
      ? pickupLocationError(areas, { ...value, pickup: value.pickup })
      : null;

  return (
    <div className="space-y-4 rounded-xl border border-cream-deep p-4 md:col-span-2">
      <p className="text-sm font-bold text-ink">موقع الاستلام</p>
      {legacy && (
        <p className="flex items-start gap-1.5 rounded-lg bg-amber-50 p-3 text-xs text-amber-900">
          <Info className="mt-0.5 h-4 w-4 shrink-0" aria-hidden /> سجل قديم بعنوان نصي: «{existing.address}». يبقى كما هو إلى أن تختار المدينة والمنطقة.
        </p>
      )}
      <div className="grid gap-4 md:grid-cols-2">
        <Field label="المدينة" required={!legacy} htmlFor="merchant-city">
          <CitySelect
            id="merchant-city"
            value={value.cityId ?? ''}
            onChange={(e) => { setFocus(null); onChange({ cityId: e.target.value || null, areaId: null, pickup: null }); }}
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
      </div>
      <Field label="تحديد موقع المتجر على الخريطة" required={!legacy} error={error || liveError || undefined}>
        <div className="space-y-2">
          <LocationSearchField label="ابحث عن موقع المتجر" onSelect={(p) => onChange({ pickup: p.position })} />
          <LocationPicker value={value.pickup} focus={focus} boundary={area?.polygon} onChange={(p) => onChange({ pickup: p })} />
        </div>
      </Field>
      {area && !hasBoundary && (
        <p className="flex items-start gap-1.5 text-xs font-medium text-amber-800">
          <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden /> هذه المنطقة بلا حدود مرسومة، فلا يمكن التحقق من أن الدبوس داخلها.
        </p>
      )}
      {value.cityId && area && value.pickup && (
        <p className="rounded-lg bg-cream px-3 py-2 text-sm">
          <b>{cityName(value.cityId)}</b> › <b>{area.name}</b> ›{' '}
          <span dir="ltr" className="text-xs">{value.pickup.lat.toFixed(5)}, {value.pickup.lng.toFixed(5)}</span>
        </p>
      )}
      <OpenDecision id="CR-1.3 §14">قائمة المدن مقترحة (المدينة الرئيسية لكل محافظة) بانتظار اعتماد مصدر رسمي للمدن والمناطق.</OpenDecision>
    </div>
  );
}
