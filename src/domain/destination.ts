import { isValidLatLng, polygonCovers } from './geo';
import type { Destination, LatLng, ServiceArea } from './types';

export const AREA_REQUIRED = 'يرجى اختيار منطقة التوصيل من القائمة';
/** Request form: a location is required — the area from the list, or a map pin inside one of the Merchant's areas. */
export const LOCATION_REQUIRED = 'حدّد موقع التوصيل: اختر المنطقة من القائمة أو اضغط على الخريطة.';
export const PIN_OUTSIDE_COVERAGE = 'هذا الموقع خارج مناطق التوصيل المتاحة لك. اختر المنطقة من القائمة أو حدّد موقعاً داخل إحدى المناطق.';
export const AREA_UNAVAILABLE = 'التوصيل إلى هذه المنطقة غير متاح حالياً. يرجى التواصل مع إدارة شهم.';
export const NO_EXACT_LOCATION = 'لم يتم تحديد موقع دقيق للعميل';
export const PINNED_LOCATION_LABEL = 'موقع محدد على الخريطة';

export const PIN_ON_SHARED_BORDER = 'هذا الموقع على الحد بين أكثر من منطقة. اختر المنطقة من القائمة.';
export const PIN_INVALID = 'الموقع الدقيق غير صالح. حرّك الدبوس أو أزله.';
export const AREA_HAS_NO_BOUNDARY = 'لا تتوفر حدود لهذه المنطقة، فلا يمكن التحقق من موقع دقيق عليها. أرسل الطلب بالمنطقة فقط.';

/**
 * An area's boundary is what a customer pin is checked against. The region catalogue is managed by
 * name (CR v1.4 §1); only areas with stored geometry accept a pin. The demo geometry is approximate —
 * authoritative boundaries still have to be imported and validated.
 */
export const hasAreaBoundary = (area: ServiceArea) => area.polygon.length >= 3;

/** The «outside the area» message, named after the area. */
export const pinOutsideAreaError = (area: ServiceArea) => `الموقع خارج منطقة التوصيل المحددة «${area.name}». حرّك الدبوس إلى داخل المنطقة أو أزله.`;

/**
 * Why a customer pin cannot be used with this area, or null. Anywhere inside the area's boundary,
 * including on the boundary itself, is accepted (owner, 2026-11-25). An area without a boundary
 * cannot verify a pin, so it is refused rather than treating the whole city as valid. The 5/10 km
 * Captain search radius plays no part here, and the pin never sets the fee.
 */
export function destinationPinError(area: ServiceArea, pin: LatLng): string | null {
  if (!isValidLatLng(pin) || (pin.lat === 0 && pin.lng === 0)) return PIN_INVALID;
  if (!hasAreaBoundary(area)) return AREA_HAS_NO_BOUNDARY;
  return polygonCovers(area.polygon, pin) ? null : pinOutsideAreaError(area);
}

export type PinAreaMatch<T> = { kind: 'one'; area: T } | { kind: 'none' } | { kind: 'ambiguous' };

/**
 * The Merchant's area that contains a pin, when the pin is dropped before an area is chosen. Only
 * areas with a boundary can match. None → `none`; on a border shared by several → `ambiguous`
 * (the Merchant chooses; never a guess).
 */
export function matchAreaForPin<T extends ServiceArea>(areas: T[], pin: LatLng): PinAreaMatch<T> {
  const matches = areas.filter((a) => hasAreaBoundary(a) && polygonCovers(a.polygon, pin));
  if (matches.length === 1) return { kind: 'one', area: matches[0] };
  return matches.length === 0 ? { kind: 'none' } : { kind: 'ambiguous' };
}

/** `matchAreaForPin` for callers that only need the single match, or null. */
export function detectAreaForPin<T extends ServiceArea>(areas: T[], pin: LatLng): T | null {
  const match = matchAreaForPin(areas, pin);
  return match.kind === 'one' ? match.area : null;
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
