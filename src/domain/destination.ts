import { pointInPolygon } from './geo';
import type { Destination, LatLng, ServiceArea } from './types';

export const AREA_REQUIRED = 'يرجى اختيار منطقة التوصيل من القائمة';
/** Request form: a location is required — the area from the list, or a map pin inside one of the Merchant's areas. */
export const LOCATION_REQUIRED = 'حدّد موقع التوصيل: اختر المنطقة من القائمة أو اضغط على الخريطة.';
export const PIN_OUTSIDE_COVERAGE = 'هذا الموقع خارج مناطق التوصيل المتاحة لك. اختر المنطقة من القائمة أو حدّد موقعاً داخل إحدى المناطق.';
export const AREA_UNAVAILABLE = 'التوصيل إلى هذه المنطقة غير متاح حالياً. يرجى التواصل مع إدارة شهم.';
export const NO_EXACT_LOCATION = 'لم يتم تحديد موقع دقيق للعميل';
export const PINNED_LOCATION_LABEL = 'موقع محدد على الخريطة';

/** Only legacy areas still carry a drawn boundary; the region catalogue is name-based (CR v1.4 §1). */
export const hasAreaBoundary = (area: ServiceArea) => area.polygon.length >= 3;

/**
 * Why a customer pin cannot be used with this area, or null. A legacy boundary is still
 * enforced; an area without one has no map pin at all (the map only accepts taps inside a
 * drawn boundary), and the pin never sets the fee.
 */
export function destinationPinError(area: ServiceArea, pin: LatLng): string | null {
  if (hasAreaBoundary(area) && !pointInPolygon(pin, area.polygon)) return `الدبوس خارج منطقة «${area.name}». حرّكه إلى داخل المنطقة أو أزله.`;
  return null;
}

/**
 * The Merchant's area that contains a pin, when the pin is dropped before an area is chosen.
 * Only areas with a drawn boundary can match; none or more than one match → null (never a guess).
 */
export function detectAreaForPin<T extends ServiceArea>(areas: T[], pin: LatLng): T | null {
  const matches = areas.filter((a) => hasAreaBoundary(a) && pointInPolygon(pin, a.polygon));
  return matches.length === 1 ? matches[0] : null;
}

/**
 * The destination with the area named once. New area-only orders store the label «منطقة X» next to
 * `areaName` X, so showing both repeated the name («منطقة الشميساني (الشميساني)»).
 * `place` is the description or chosen place when it adds something; `area` is always the area.
 */
export function destinationParts(order: { destination: { label: string }; areaName: string }): { place?: string; area: string } {
  const label = order.destination.label.trim();
  const redundant = !label || label === order.areaName || label === `منطقة ${order.areaName}`;
  return redundant ? { area: order.areaName } : { place: label, area: order.areaName };
}

/** One-line destination: «خلف سيتي مول · خلدا», or just «خلدا» when there is nothing more specific. */
export function destinationText(order: { destination: { label: string }; areaName: string }): string {
  const { place, area } = destinationParts(order);
  return place ? `${place} · ${area}` : area;
}

/** New orders without a pin have no coordinates. Older demo orders keep an `approximate` zone centre instead. */
export const isAreaOnly = (destination: Destination) => !destination.position;
