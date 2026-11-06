import { pointInPolygon } from './geo';
import type { Destination, LatLng, ServiceArea } from './types';

export const AREA_REQUIRED = 'يرجى اختيار منطقة التوصيل من القائمة';
export const AREA_UNAVAILABLE = 'التوصيل إلى هذه المنطقة غير متاح حالياً. يرجى التواصل مع إدارة شهم.';
export const NO_EXACT_LOCATION = 'لم يتم تحديد موقع دقيق للعميل';
export const PINNED_LOCATION_LABEL = 'موقع محدد على الخريطة';

export const hasAreaBoundary = (area: ServiceArea) => area.polygon.length >= 3;

/** Why a customer pin cannot be used with this area, or null when it is inside the boundary. */
export function destinationPinError(area: ServiceArea, pin: LatLng): string | null {
  if (!hasAreaBoundary(area)) return `لا توجد حدود مرسومة لمنطقة «${area.name}»، لذا لا يمكن التحقق من الموقع الدقيق. أزل الدبوس لإرسال الطلب بالمنطقة فقط.`;
  if (!pointInPolygon(pin, area.polygon)) return `الدبوس خارج منطقة «${area.name}». حرّكه إلى داخل المنطقة أو أزله.`;
  return null;
}

/** New orders without a pin have no coordinates. Older demo orders keep an `approximate` zone centre instead. */
export const isAreaOnly = (destination: Destination) => !destination.position;
