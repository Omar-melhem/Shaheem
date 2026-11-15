import { describe, expect, it } from 'vitest';
import { areaFullPath, areaLabel, childrenOf, isDestinationActive, isSubArea, topLevelAreas } from '@/domain/regions';
import { governorateName, GOVERNORATES, isGovernorateId } from '@/domain/governorates';
import { cityName, citiesOf, CITIES, findCity, isCityInGovernorate } from '@/domain/cities';
import { makeArea } from '../../fixtures';

const khalda = makeArea({ id: 'a-khalda', name: 'خلدا' });
const east = makeArea({ id: 's-east', name: 'الحي الشرقي', parentId: 'a-khalda' });
const alef = makeArea({ id: 's-alef', name: 'أ', parentId: 'a-khalda' });
const other = makeArea({ id: 'a-other', name: 'عبدون' });
const areas = [khalda, east, alef, other];

describe('region catalogue', () => {
  it('a sub-area is one with a parent', () => {
    expect(isSubArea(east)).toBe(true);
    expect(isSubArea(khalda)).toBe(false);
  });

  it('childrenOf returns the sections of an area sorted by Arabic name', () => {
    expect(childrenOf(areas, 'a-khalda').map((a) => a.id)).toEqual(['s-alef', 's-east']);
  });

  it('topLevelAreas excludes sections', () => {
    expect(topLevelAreas(areas).map((a) => a.id)).toEqual(['a-khalda', 'a-other']);
  });

  it('a section is orderable only while its parent is active', () => {
    expect(isDestinationActive(east, areas)).toBe(true);
    const stoppedParent = [{ ...khalda, status: 'inactive' as const }, east];
    expect(isDestinationActive(east, stoppedParent)).toBe(false);
  });

  it('a stopped area or section is never orderable', () => {
    expect(isDestinationActive({ ...khalda, status: 'inactive' }, areas)).toBe(false);
    expect(isDestinationActive({ ...east, status: 'inactive' }, areas)).toBe(false);
  });

  it('a section whose parent is missing is not orderable', () => {
    expect(isDestinationActive(east, [east])).toBe(false);
  });

  it('labels a section with its parent and an area with its own name', () => {
    expect(areaLabel(east, areas)).toBe('خلدا › الحي الشرقي');
    expect(areaLabel(khalda, areas)).toBe('خلدا');
  });

  it('full path starts with the city', () => {
    expect(areaFullPath(east, areas)).toBe('عمّان › خلدا › الحي الشرقي');
  });
});

describe('governorates', () => {
  it('lists the twelve governorates of Jordan', () => {
    expect(GOVERNORATES).toHaveLength(12);
  });

  it('accepts only known governorate ids', () => {
    expect(isGovernorateId('irbid')).toBe(true);
    expect(isGovernorateId('nowhere')).toBe(false);
    expect(isGovernorateId(undefined)).toBe(false);
  });

  it('names a governorate, or says it is unspecified', () => {
    expect(governorateName('aqaba')).toBe('العقبة');
    expect(governorateName(undefined)).toBe('غير محددة');
  });
});

describe('cities', () => {
  it('every city belongs to a known governorate', () => {
    for (const c of CITIES) expect(isGovernorateId(c.governorateId)).toBe(true);
  });

  it('citiesOf filters by governorate (Salt is in Balqa)', () => {
    expect(citiesOf('balqa').map((c) => c.id)).toEqual(['salt']);
    expect(citiesOf('nowhere')).toEqual([]);
  });

  it('findCity / cityName handle missing ids', () => {
    expect(findCity('irbid')?.name).toBe('إربد');
    expect(findCity(null)).toBeUndefined();
    expect(cityName(undefined)).toBe('غير محددة');
  });

  it('a city is a separate layer from its governorate', () => {
    expect(isCityInGovernorate('salt', 'balqa')).toBe(true);
    expect(isCityInGovernorate('salt', 'amman')).toBe(false);
    expect(isCityInGovernorate('nowhere', 'amman')).toBe(false);
  });
});
