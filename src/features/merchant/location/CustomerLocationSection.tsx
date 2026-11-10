import { useId, useState } from 'react';
import { AlertTriangle, CheckCircle2, Info, X } from 'lucide-react';
import type { MerchantZoneOption } from '@/application/queries';
import { NO_EXACT_LOCATION, hasAreaBoundary } from '@/domain/destination';
import { formatMoney } from '@/domain/money';
import type { ID, LatLng, ServiceArea } from '@/domain/types';
import { Field, OpenDecision, Select } from '@/shared/components/ui';
import { DestinationMapPicker } from './DestinationMapPicker';
import { LocationSearchField } from './LocationSearchField';

export interface CustomerLocation {
  position: LatLng;
  placeName?: string;
}

/**
 * Required delivery area (it sets the fee), chosen from the Merchant's own list, followed by an
 * optional exact location on the map (it only helps the Captain). The two stay separate here
 * and on the order.
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
      <Field label="منطقة التوصيل" required htmlFor={areaFieldId} error={areaError}>
        <Select id={areaFieldId} value={areaId ?? ''} onChange={(e) => onSelectArea(e.target.value || null)} aria-invalid={!!areaError}>
          <option value="">اختر منطقة التوصيل</option>
          {options.map((o) => (
            <option key={o.area.id} value={o.area.id}>{o.label} — {formatMoney(o.price)}</option>
          ))}
        </Select>
      </Field>

      <div className="space-y-2" data-invalid={!!pinError} tabIndex={pinError ? -1 : undefined}>
        <div className="flex items-center justify-between gap-2">
          <p className="flex items-center gap-2 text-sm font-bold text-ink">
            موقع العميل على الخريطة
            <span className="rounded-full bg-cream px-2 py-0.5 text-[11px] font-medium text-ink-soft">اختياري</span>
          </p>
          {location ? (
            <button type="button" onClick={removePin} className="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline">
              <X className="h-3.5 w-3.5" aria-hidden /> إزالة الموقع
            </button>
          ) : (
            <span className="text-xs text-ink-muted">تحديد الموقع</span>
          )}
        </div>

        {canPin && (
          <LocationSearchField
            key={`${area.id}-${placeSearchKey}`}
            label="ابحث عن شارع أو مكان داخل المنطقة"
            placeholder="ابحث عن شارع أو مكان داخل المنطقة"
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
          !pinError && (
            <p className="flex flex-wrap items-center gap-1.5 text-xs text-ink-soft" aria-live="polite">
              <CheckCircle2 className="h-4 w-4 shrink-0 text-secondary" aria-hidden /> اسحب الدبوس لتحديد موقع العميل بدقة.
              {location.placeName && <span className="text-ink-muted">· {location.placeName}</span>}
            </p>
          )
        ) : !area ? (
          <p className="text-xs text-ink-muted">اختر منطقة التوصيل أولاً لتظهر على الخريطة.</p>
        ) : canPin ? (
          <p className="text-xs text-ink-muted">{NO_EXACT_LOCATION}. يمكنك إرسال الطلب بالمنطقة فقط، أو الضغط داخل المنطقة لإضافة موقع دقيق يساعد الكابتن.</p>
        ) : (
          <p className="text-xs text-ink-muted">لا توجد حدود مرسومة لهذه المنطقة، لذا لا يمكن تحديد موقع دقيق عليها. يمكنك إرسال الطلب بالمنطقة فقط.</p>
        )}
        {canPin && <OpenDecision id="O-018">البحث من OpenStreetMap للعرض؛ مزوّد الخرائط والبحث النهائي لم يُعتمد بعد.</OpenDecision>}
      </div>
    </div>
  );
}
