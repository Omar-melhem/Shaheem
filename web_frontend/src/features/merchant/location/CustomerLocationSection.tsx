import { useId, useState } from 'react';
import { AlertTriangle, CheckCircle2, Info, X } from 'lucide-react';
import type { MerchantZoneOption } from '@/application/queries';
import { NO_EXACT_LOCATION, hasAreaBoundary } from '@/domain/destination';
import type { ID, LatLng, ServiceArea } from '@/domain/types';
import { Button, Field, OpenDecision } from '@/shared/components/ui';
import { DestinationMapPicker } from './DestinationMapPicker';
import { LocationSearchField } from './LocationSearchField';
import { ServiceAreaCombobox } from './ServiceAreaCombobox';

export interface CustomerLocation {
  position: LatLng;
  placeName?: string;
}

/**
 * Required delivery area (it sets the fee) followed by an optional exact location
 * (it only helps the Captain). The two stay separate here and on the order.
 */
export function CustomerLocationSection({
  options,
  areaId,
  area,
  areaError,
  location,
  pinError,
  pinNotice,
  pickup,
  onSelectArea,
  onPinChange,
}: {
  /** The Merchant's enabled, priced delivery areas. */
  options: MerchantZoneOption[];
  areaId: ID | null;
  area: ServiceArea | null;
  areaError?: string;
  location: CustomerLocation | null;
  pinError: string | null;
  /** Explains that changing the area removed an incompatible pin. */
  pinNotice: string | null;
  pickup: LatLng;
  onSelectArea: (areaId: ID | null) => void;
  onPinChange: (location: CustomerLocation | null) => void;
}) {
  const areaFieldId = useId();
  const [placeSearchKey, setPlaceSearchKey] = useState(0);
  const canPin = !!area && hasAreaBoundary(area);

  const removePin = () => {
    onPinChange(null);
    setPlaceSearchKey((k) => k + 1); // a leftover place name would look like a chosen location
  };

  return (
    <div className="space-y-5">
      <Field label="منطقة التوصيل" required htmlFor={areaFieldId} error={areaError} hint="رسوم التوصيل تُحدَّد حسب المنطقة التي تختارها.">
        <ServiceAreaCombobox id={areaFieldId} options={options} selectedId={areaId} invalid={!!areaError} onSelect={onSelectArea} />
      </Field>

      <Field label="الموقع الدقيق للعميل" optional>
        <div className="space-y-2" data-invalid={!!pinError} tabIndex={pinError ? -1 : undefined}>
          {canPin && (
            <LocationSearchField
              key={`${area.id}-${placeSearchKey}`}
              label="ابحث عن شارع أو مكان داخل المنطقة (اختياري)"
              placeholder="ابحث عن شارع أو مكان داخل المنطقة (اختياري)"
              onSelect={(p) => onPinChange({ position: p.position, placeName: p.name })}
            />
          )}
          <DestinationMapPicker value={location?.position ?? null} pickup={pickup} area={area} onChange={(position) => onPinChange({ position })} />

          {pinNotice && (
            <p className="flex items-start gap-1.5 text-sm font-medium text-amber-800" role="status">
              <Info className="mt-0.5 h-4 w-4 shrink-0" aria-hidden /> {pinNotice}
            </p>
          )}
          {pinError && (
            <p className="flex items-start gap-1.5 text-sm font-medium text-red-700" role="alert">
              <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden /> {pinError}
            </p>
          )}
          {location ? (
            <div className="flex flex-wrap items-center justify-between gap-2">
              {!pinError && (
                <p className="flex items-center gap-1.5 text-sm font-medium text-secondary" aria-live="polite">
                  <CheckCircle2 className="h-4 w-4 shrink-0" aria-hidden /> تم تحديد موقع دقيق للعميل
                  {location.placeName && <span className="text-ink-muted">· {location.placeName}</span>}
                </p>
              )}
              <Button size="sm" variant="outline" icon={<X className="h-4 w-4" />} onClick={removePin}>إزالة الدبوس</Button>
            </div>
          ) : !area ? (
            <p className="text-xs text-ink-muted">اختر منطقة التوصيل أولاً لتظهر حدودها على الخريطة.</p>
          ) : canPin ? (
            <p className="text-xs text-ink-muted">{NO_EXACT_LOCATION}. يمكنك إرسال الطلب بالمنطقة فقط، أو الضغط داخل المنطقة لإضافة موقع دقيق يساعد الكابتن.</p>
          ) : (
            <p className="text-xs text-ink-muted">لا توجد حدود مرسومة لهذه المنطقة، لذا لا يمكن تحديد موقع دقيق عليها. يمكنك إرسال الطلب بالمنطقة فقط.</p>
          )}
          <OpenDecision id="O-018">البحث من OpenStreetMap للعرض؛ مزوّد الخرائط والبحث النهائي لم يُعتمد بعد.</OpenDecision>
        </div>
      </Field>
    </div>
  );
}
