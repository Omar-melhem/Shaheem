import type { ID, ServiceArea } from './types';
import { cityName } from './cities';

// Data-driven region catalogue (CR v1.4 §1): Governorate → City → Area → optional Sub-areas.
// A sub-area is a ServiceArea whose `parentId` points at a top-level area; one level only.
// Each area and sub-area is its own destination with its own explicit price (no inheritance).

export const isSubArea = (a: ServiceArea) => !!a.parentId;

export const childrenOf = (areas: ServiceArea[], parentId: ID) =>
  areas.filter((a) => a.parentId === parentId).sort((a, b) => a.name.localeCompare(b.name, 'ar'));

export const topLevelAreas = (areas: ServiceArea[]) => areas.filter((a) => !a.parentId);

/** A destination is orderable only if it and (for a sub-area) its parent are active. */
export function isDestinationActive(area: ServiceArea, areas: ServiceArea[]): boolean {
  if (area.status !== 'active') return false;
  if (!area.parentId) return true;
  return areas.find((p) => p.id === area.parentId)?.status === 'active';
}

/** "خلدا › الحي الشرقي" — the name a Merchant, Captain and Admin all see for a destination. */
export function areaLabel(area: ServiceArea, areas: ServiceArea[]): string {
  const parent = area.parentId ? areas.find((p) => p.id === area.parentId) : undefined;
  return parent ? `${parent.name} › ${area.name}` : area.name;
}

/** Full path including the city, for printed lists and Admin tables. */
export const areaFullPath = (area: ServiceArea, areas: ServiceArea[]) => `${cityName(area.cityId)} › ${areaLabel(area, areas)}`;
