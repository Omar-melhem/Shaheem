import { useId, useMemo, useState } from 'react';
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
 * The delivery location is required and satisfied by either the area list or a map pin (owner
 * review 2026-11-21). The area sets the fee; a pin dropped before choosing an area selects the
 * Merchant's area that contains it (the form does that). The area and the pin stay separate on
 * the order.
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
  /** Explains an automatic area choice, or that changing the area removed an incompatible pin. */
  pinNotice: string | null;
  pickup: LatLng;
  onSelectArea: (areaId: ID | null) => void;
  onPinChange: (location: CustomerLocation | null) => void;
}) {
  const areaFieldId = useId();
  const groupId = useId();
  const [placeSearchKey, setPlaceSearchKey] = useState(0);
  const pinnableAreas = useMemo(() => options.map((o) => o.area).filter(hasAreaBoundary), [options]);
  const canPin = area ? hasAreaBoundary(area) : pinnableAreas.length > 0;

  const removePin = () => {
    onPinChange(null);
    setPlaceSearchKey((k) => k + 1); // a leftover place name would look like a chosen location
  };

  return (
    <div className="space-y-4" role="group" aria-labelledby={`${groupId}-title`} aria-describedby={`${groupId}-hint`}>
      <div>
        <p id={`${groupId}-title`} className="flex items-center gap-2 text-sm font-bold text-ink">
          موقع التوصيل
          <span className="rounded-full bg-primary-50 px-2 py-0.5 text-[11px] font-bold text-primary">مطلوب</span>
        </p>
        <p id={`${groupId}-hint`} className="mt-1 text-xs text-ink-muted">اختر المنطقة من القائمة أو اضغط على الخريطة — يكفي أحدهما.</p>
      </div>

      <Field label="منطقة التوصيل" htmlFor={areaFieldId} error={areaError}>
        <Select id={areaFieldId} value={areaId ?? ''} onChange={(e) => onSelectArea(e.target.value || null)} aria-invalid={!!areaError}>
          <option value="">اختر منطقة التوصيل</option>
          {options.map((o) => (
            <option key={o.area.id} value={o.area.id}>{o.label} — {formatMoney(o.price)}</option>
          ))}
        </Select>
      </Field>

      <div className="space-y-2" data-invalid={!!pinError} tabIndex={pinError ? -1 : undefined}>
        <div className="flex items-center justify-between gap-2">
          <p className="text-sm font-bold text-ink">{area ? 'الموقع الدقيق على الخريطة' : 'أو حدّد الموقع على الخريطة'}</p>
          {location && (
            <button type="button" onClick={removePin} className="inline-flex items-center gap-1 text-xs font-bold text-primary hover:underline">
              <X className="h-3.5 w-3.5" aria-hidden /> إزالة الموقع
            </button>
          )}
        </div>

        {canPin && (
          <LocationSearchField
            key={`${area?.id ?? 'any'}-${placeSearchKey}`}
            label={area ? 'ابحث عن شارع أو مكان داخل المنطقة' : 'ابحث عن شارع أو مكان'}
            placeholder={area ? 'ابحث عن شارع أو مكان داخل المنطقة' : 'ابحث عن شارع أو مكان'}
            onSelect={(p) => onPinChange({ position: p.position, placeName: p.name })}
          />
        )}
        <DestinationMapPicker value={location?.position ?? null} pickup={pickup} area={area} selectableAreas={pinnableAreas} onChange={(position) => onPinChange({ position })} />

        {pinNotice && (
          <p className="flex items-start gap-1.5 text-sm font-medium text-secondary" role="status">
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
              <CheckCircle2 className="h-4 w-4 shrink-0 text-secondary" aria-hidden /> حُدّد موقع العميل. لتغييره اضغط مكاناً آخر على الخريطة أو ابحث عنه.
              {location.placeName && <span className="text-ink-muted">· {location.placeName}</span>}
            </p>
          )
        ) : !area ? (
          <p className="text-xs text-ink-muted">
            {canPin ? 'اضغط داخل إحدى المناطق المظلّلة، وتُختار المنطقة تلقائياً.' : 'اختر منطقة التوصيل من القائمة.'}
          </p>
        ) : canPin ? (
          <p className="text-xs text-ink-muted">{NO_EXACT_LOCATION}. المنطقة تكفي للإرسال، والموقع الدقيق يساعد الكابتن.</p>
        ) : (
          <p className="text-xs text-ink-muted">لا توجد حدود مرسومة لهذه المنطقة، لذا لا يمكن تحديد موقع دقيق عليها. المنطقة تكفي للإرسال.</p>
        )}
        {canPin && (
          <OpenDecision id="O-018 · حدود">أي نقطة داخل حدود المنطقة أو على حدها مقبولة. حدود المناطق في هذا النموذج تقريبية للعرض، والحدود الرسمية لم تُستورد بعد؛ البحث من OpenStreetMap للعرض.</OpenDecision>
        )}
      </div>
    </div>
  );
}
