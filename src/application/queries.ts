import type { ID, LatLng, Money, ServiceArea } from '@/domain/types';
import { areasContaining } from '@/domain/geo';
import type { AppData } from '@/infrastructure/seed';

type PricingData = Pick<AppData, 'areas' | 'prices'>;

export type ZoneFeeResolution =
  | { kind: 'ok'; area: ServiceArea; price: Money }
  | { kind: 'zone_unavailable' }
  | { kind: 'no_price'; area: ServiceArea };

/**
 * Merchant + customer zone → fixed delivery fee (Zone-Based Pricing Spec §6, §8).
 * No distance or GPS is involved. Every non-ok outcome blocks the order.
 */
export function resolveZoneFee(data: PricingData, merchantId: ID, zoneId: ID): ZoneFeeResolution {
  const area = data.areas.find((a) => a.id === zoneId);
  if (!area || area.status !== 'active') return { kind: 'zone_unavailable' };
  const price = data.prices.find((p) => p.merchantId === merchantId && p.areaId === zoneId);
  if (!price || price.status !== 'active' || !(price.price > 0)) return { kind: 'no_price', area };
  return { kind: 'ok', area, price: price.price };
}

export type LocationFeeResolution = ZoneFeeResolution | { kind: 'outside' };

/**
 * Customer pin → the active zone whose boundary contains it → the Merchant's fixed
 * fee for that zone. Owner decision (2026-11-02): the Merchant pins the customer like
 * in a delivery app and the zone is detected from the pin. Only zones with a drawn
 * boundary can match; if zones overlap, the first one this Merchant serves wins.
 */
export function resolveLocationFee(data: PricingData, merchantId: ID, point: LatLng): LocationFeeResolution {
  const candidates = areasContaining(point, data.areas.filter((a) => a.status === 'active'));
  if (candidates.length === 0) return { kind: 'outside' };
  for (const area of candidates) {
    const r = resolveZoneFee(data, merchantId, area.id);
    if (r.kind === 'ok') return r;
  }
  return { kind: 'no_price', area: candidates[0] };
}

export interface MerchantZoneOption {
  area: ServiceArea;
  price: Money;
}

/** Zones a Merchant may select: central zone active + Merchant price enabled and valid. */
export function merchantZoneOptions(data: PricingData, merchantId: ID): MerchantZoneOption[] {
  return data.prices
    .filter((p) => p.merchantId === merchantId && p.status === 'active' && p.price > 0)
    .map((p) => ({ area: data.areas.find((a) => a.id === p.areaId), price: p.price }))
    .filter((o): o is MerchantZoneOption => !!o.area && o.area.status === 'active')
    .sort((a, b) => a.area.name.localeCompare(b.area.name, 'ar'));
}
