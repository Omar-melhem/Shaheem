import type { ID, LatLng, Merchant, ServiceArea } from '@/domain/types';
import { cityName, findCity } from '@/domain/cities';
import { isValidLatLng, pointInPolygon } from '@/domain/geo';

export interface PickupLocationInput {
  cityId: string | null;
  areaId: ID | null;
  pickup: LatLng;
}

export const PIN_OUTSIDE_AREA = 'موقع المتجر خارج حدود المنطقة المختارة. حرّك الدبوس أو اختر المنطقة الصحيحة.';

/**
 * Validates City → Area → pin for a Merchant (CR v1.3 §3.2). The Area is never reassigned
 * silently: a pin outside the chosen Area's polygon is an error for Admin to resolve.
 * Areas without a drawn boundary cannot be checked; the form states that limitation.
 */
export function pickupLocationError(areas: ServiceArea[], input: PickupLocationInput): string | null {
  if (!findCity(input.cityId)) return 'اختر المدينة';
  const area = areas.find((a) => a.id === input.areaId);
  if (!area || area.cityId !== input.cityId) return 'اختر منطقة تابعة للمدينة المختارة';
  if (!isValidLatLng(input.pickup)) return 'حدّد موقع المتجر على الخريطة';
  if (area.polygon.length >= 3 && !pointInPolygon(input.pickup, area.polygon)) return PIN_OUTSIDE_AREA;
  return null;
}

/** A legacy Merchant (text address only, no City/Area) stays valid until Admin changes its location. */
export const isUnchangedLegacyLocation = (existing: Merchant | undefined, input: PickupLocationInput): boolean =>
  !!existing && !existing.areaId && !input.cityId && !input.areaId && existing.pickup.lat === input.pickup?.lat && existing.pickup.lng === input.pickup?.lng;

/** Display label kept for screens that show `Merchant.address`; IDs and coordinates remain the source of truth. */
export function pickupAddressLabel(areas: ServiceArea[], existing: Merchant | undefined, input: PickupLocationInput): string {
  if (existing && existing.areaId === input.areaId && existing.cityId === input.cityId) return existing.address;
  const area = areas.find((a) => a.id === input.areaId);
  return `${area?.name ?? ''}، ${cityName(input.cityId)}`;
}
