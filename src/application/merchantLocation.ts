import type { ID, LatLng, Merchant, ServiceArea } from '@/domain/types';
import { cityName, findCity } from '@/domain/cities';
import { isValidLatLng } from '@/domain/geo';

export interface PickupLocationInput {
  cityId: string | null;
  areaId: ID | null;
  pickup: LatLng;
}

export const PICKUP_REQUIRED = 'حدّد موقع المتجر: اضغط على الخريطة أو ابحث باسم المتجر أو العنوان';

/**
 * Validates a Merchant **record** (owner, 2026-11-25): City → Area from the catalogue (any area, priced
 * or not) and any real coordinate. Registration is never limited by delivery zones, an area's
 * boundary or the captain search radius — those are order/dispatch policies, checked separately.
 * The Area is stored as chosen and is never reassigned from the coordinate. (0,0) is treated as
 * "not set".
 */
export function pickupLocationError(areas: ServiceArea[], input: PickupLocationInput): string | null {
  if (!findCity(input.cityId)) return 'اختر المدينة';
  const area = areas.find((a) => a.id === input.areaId);
  if (!area || area.cityId !== input.cityId) return 'اختر منطقة تابعة للمدينة المختارة';
  if (!isValidLatLng(input.pickup) || (input.pickup.lat === 0 && input.pickup.lng === 0)) return PICKUP_REQUIRED;
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
