import { pointInPolygon } from './geo';
import type { Destination, LatLng, ServiceArea } from './types';

export const AREA_REQUIRED = 'يرجى اختيار منطقة التوصيل من القائمة';
export const AREA_UNAVAILABLE = 'التوصيل إلى هذه المنطقة غير متاح حالياً. يرجى التواصل مع إدارة شهم.';
export const NO_EXACT_LOCATION = 'لم يتم تحديد موقع دقيق للعميل';
export const PINNED_LOCATION_LABEL = 'موقع محدد على الخريطة';
export const PIN_UNVERIFIED = 'هذه المنطقة بلا حدود على الخريطة، فلا يمكن التحقق من أن الدبوس داخلها. تأكد من الموقع قبل الإرسال.';

/** Only legacy areas still carry a drawn boundary; the region catalogue is name-based (CR v1.4 §1). */
export const hasAreaBoundary = (area: ServiceArea) => area.polygon.length >= 3;

/**
 * Why a customer pin cannot be used with this area, or null. A legacy boundary is still
 * enforced; an area without one accepts the pin unverified (shown as PIN_UNVERIFIED),
 * because the pin is optional help for the Captain and never sets the area or the fee.
 */
export function destinationPinError(area: ServiceArea, pin: LatLng): string | null {
  if (hasAreaBoundary(area) && !pointInPolygon(pin, area.polygon)) return `الدبوس خارج منطقة «${area.name}». حرّكه إلى داخل المنطقة أو أزله.`;
  return null;
}

/** New orders without a pin have no coordinates. Older demo orders keep an `approximate` zone centre instead. */
export const isAreaOnly = (destination: Destination) => !destination.position;
