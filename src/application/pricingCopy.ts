import type { ID, Money } from '@/domain/types';
import type { AppData } from '@/application/data';

type PricingData = Pick<AppData, 'areas' | 'prices'>;

/** fill_missing never touches an existing target price; overwrite replaces differing prices. */
export type PricingCopyMode = 'fill_missing' | 'overwrite';

export type PricingCopyAction = 'add' | 'update' | 'unchanged' | 'kept' | 'skipped';

export interface PricingCopyRow {
  areaId: ID;
  areaName: string;
  sourcePrice: Money;
  targetPrice?: Money;
  action: PricingCopyAction;
  skipReason?: string;
}

export interface PricingCopyPreview {
  rows: PricingCopyRow[];
  counts: Record<PricingCopyAction, number>;
  /** Rows the copy would write. */
  changes: number;
}

/**
 * What a copy would do, per source price (CR v1.3 §4). Areas match by ID. Areas that are
 * stopped centrally or disabled at the source are skipped and shown, pending an owner rule (§14).
 * Only price rows are involved — never orders, pickup data or Merchant identity.
 */
export function previewPricingCopy(data: PricingData, sourceId: ID, targetId: ID, mode: PricingCopyMode): PricingCopyPreview {
  const rows = data.prices
    .filter((p) => p.merchantId === sourceId)
    .map((source): PricingCopyRow => {
      const area = data.areas.find((a) => a.id === source.areaId);
      const target = data.prices.find((p) => p.merchantId === targetId && p.areaId === source.areaId);
      const base = { areaId: source.areaId, areaName: area?.name ?? '—', sourcePrice: source.price, targetPrice: target?.price };
      if (!area || area.status !== 'active') return { ...base, action: 'skipped', skipReason: 'المنطقة متوقفة' };
      if (source.status !== 'active') return { ...base, action: 'skipped', skipReason: 'معطّلة لدى المتجر المصدر' };
      if (!target) return { ...base, action: 'add' };
      if (target.price === source.price) return { ...base, action: 'unchanged' };
      return { ...base, action: mode === 'overwrite' ? 'update' : 'kept' };
    })
    .sort((a, b) => a.areaName.localeCompare(b.areaName, 'ar'));
  const counts: PricingCopyPreview['counts'] = { add: 0, update: 0, unchanged: 0, kept: 0, skipped: 0 };
  rows.forEach((r) => { counts[r.action] += 1; });
  return { rows, counts, changes: counts.add + counts.update };
}
