import type { ID, Money, ServiceArea } from '@/domain/types';
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
