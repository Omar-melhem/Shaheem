import type { ID, Money, ServiceArea } from '@/domain/types';
import { areaLabel, isDestinationActive } from '@/domain/regions';
import type { AppData } from '@/infrastructure/seed';

type PricingData = Pick<AppData, 'areas' | 'prices' | 'coverage'>;

export type ZoneFeeResolution =
  | { kind: 'ok'; area: ServiceArea; price: Money }
  | { kind: 'zone_unavailable' }
  | { kind: 'not_covered'; area: ServiceArea }
  | { kind: 'no_price'; area: ServiceArea };

export const isCovered = (data: Pick<AppData, 'coverage'>, merchantId: ID, areaId: ID) =>
  data.coverage.some((c) => c.merchantId === merchantId && c.areaId === areaId);

/**
 * Merchant + destination → fixed delivery fee (Zone-Based Pricing Spec §6, §8). Orderable only
 * when the destination is active, the Merchant covers it, AND an explicit price exists
 * (CR v1.4 §2: coverage is not a price). No distance or GPS is involved.
 */
export function resolveZoneFee(data: PricingData, merchantId: ID, zoneId: ID): ZoneFeeResolution {
  const area = data.areas.find((a) => a.id === zoneId);
  if (!area || !isDestinationActive(area, data.areas)) return { kind: 'zone_unavailable' };
  if (!isCovered(data, merchantId, zoneId)) return { kind: 'not_covered', area };
  const price = data.prices.find((p) => p.merchantId === merchantId && p.areaId === zoneId);
  if (!price || price.status !== 'active' || !(price.price > 0)) return { kind: 'no_price', area };
  return { kind: 'ok', area, price: price.price };
}

export interface MerchantZoneOption {
  area: ServiceArea;
  /** "Area › Section" for a sub-area, so the parent is always named. */
  label: string;
  price: Money;
}

/** Destinations a Merchant may order to: active, covered and priced. */
export function merchantZoneOptions(data: PricingData, merchantId: ID): MerchantZoneOption[] {
  return data.coverage
    .filter((c) => c.merchantId === merchantId)
    .map((c) => resolveZoneFee(data, merchantId, c.areaId))
    .filter((r): r is Extract<ZoneFeeResolution, { kind: 'ok' }> => r.kind === 'ok')
    .map((r) => ({ area: r.area, label: areaLabel(r.area, data.areas), price: r.price }))
    .sort((a, b) => a.label.localeCompare(b.label, 'ar'));
}
