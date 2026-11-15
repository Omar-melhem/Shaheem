import { describe, expect, it } from 'vitest';
import { failureOf, newStore, valueOf } from './storeHarness';

const zone = (over: Record<string, unknown> = {}) => ({ governorateId: 'amman', cityId: 'amman', name: 'النخيل', aliases: [], ...over });

describe('createZone', () => {
  it.each([
    [{ parentId: 'a-nowhere' }, 'المنطقة الأم غير موجودة'],
    [{ governorateId: 'nowhere' }, 'اختر المحافظة أولاً'],
    [{ cityId: 'irbid' }, 'اختر مدينة تابعة للمحافظة'],
    [{ name: '  ' }, 'اسم المنطقة مطلوب'],
  ])('rejects %j', (over, message) => {
    const { state } = newStore();
    expect(failureOf(state().createZone(zone(over)))).toBe(message);
  });

  it('rejects a duplicate name or alias among siblings (spelling-insensitive)', () => {
    const { state } = newStore();
    expect(failureOf(state().createZone(zone({ name: 'khalda' })))).toContain('«خلدا»');
    expect(failureOf(state().createZone(zone({ name: 'جديد', aliases: ['ام اذينة'] })))).toContain('«أم أذينة»');
  });

  it('allows the same name in another city', () => {
    const { state } = newStore();
    valueOf(state().createZone(zone({ governorateId: 'irbid', cityId: 'irbid', name: 'خلدا' })));
  });

  it('a section inherits its parent governorate and city and cannot nest', () => {
    const { state } = newStore();
    const id = valueOf(state().createZone(zone({ parentId: 'a-khalda', name: 'الحي الشرقي', governorateId: 'irbid', cityId: 'irbid' })));
    expect(state().areas.find((a) => a.id === id)).toMatchObject({ parentId: 'a-khalda', governorateId: 'amman', cityId: 'amman', polygon: [] });
    expect(failureOf(state().createZone(zone({ parentId: id, name: 'فرعي' })))).toBe('لا يمكن إضافة قسم داخل قسم — اختر منطقة رئيسية');
    expect(failureOf(state().createZone(zone({ parentId: 'a-khalda', name: '' })))).toBe('اسم القسم مطلوب');
  });
});

describe('updateZone / setServiceAreaStatus', () => {
  it('validates and updates name, aliases and notes', () => {
    const { state } = newStore();
    expect(failureOf(state().updateZone('a-nowhere', { name: 'x' }))).toBe('المنطقة غير موجودة');
    expect(failureOf(state().updateZone('a-khalda', { name: ' ' }))).toBe('اسم المنطقة مطلوب');
    expect(failureOf(state().updateZone('a-khalda', { name: 'عبدون' }))).toContain('«عبدون»');
    valueOf(state().updateZone('a-khalda', { name: 'خلدا الجديدة', aliases: [' Khalda ', ''], notes: '  ' }));
    expect(state().areas.find((a) => a.id === 'a-khalda')).toMatchObject({ name: 'خلدا الجديدة', aliases: ['Khalda'], notes: undefined });
  });

  it('a section follows its parent city', () => {
    const { state } = newStore();
    const id = valueOf(state().createZone(zone({ parentId: 'a-khalda', name: 'قسم' })));
    expect(failureOf(state().updateZone(id, { cityId: 'irbid', governorateId: 'irbid' }))).toBe('القسم يتبع مدينة منطقته الأم');
  });

  it('an area with sections, or linked to merchants, cannot move city', () => {
    const { state } = newStore();
    valueOf(state().createZone(zone({ parentId: 'a-khalda', name: 'قسم' })));
    expect(failureOf(state().updateZone('a-khalda', { cityId: 'irbid', governorateId: 'irbid' }))).toBe('لا يمكن نقل منطقة لها أقسام إلى مدينة أخرى');
    expect(failureOf(state().updateZone('a-jubaiha', { cityId: 'irbid', governorateId: 'irbid' }))).toBe('لا يمكن نقل منطقة مرتبطة بمواقع تجار إلى مدينة أخرى');
    expect(failureOf(state().updateZone('a-uthaina', { cityId: 'irbid' }))).toBe('اختر مدينة تابعة للمحافظة');
  });

  it('stops and restarts an area', () => {
    const { state } = newStore();
    expect(failureOf(state().setServiceAreaStatus('a-nowhere', false))).toBe('المنطقة غير موجودة');
    valueOf(state().setServiceAreaStatus('a-abdoun', false));
    expect(state().areas.find((a) => a.id === 'a-abdoun')?.status).toBe('inactive');
  });
});

describe('importAreas (bulk names)', () => {
  it('validates location and lines', () => {
    const { state } = newStore();
    expect(failureOf(state().importAreas({ governorateId: 'x', cityId: 'amman', lines: 'a' }))).toBe('اختر المحافظة أولاً');
    expect(failureOf(state().importAreas({ governorateId: 'amman', cityId: 'irbid', lines: 'a' }))).toBe('اختر مدينة تابعة للمحافظة');
    expect(failureOf(state().importAreas({ governorateId: 'amman', cityId: 'amman', lines: ' \n ' }))).toBe('اكتب اسم منطقة واحدة على الأقل');
    expect(failureOf(state().importAreas({ governorateId: 'amman', cityId: 'amman', lines: 'أ / ب / ج' }))).toContain('مستويان كحد أقصى');
  });

  it('creates new areas and sections and skips existing names', () => {
    const { state } = newStore();
    const result = valueOf(state().importAreas({ governorateId: 'amman', cityId: 'amman', lines: 'النخيل\nالنخيل / الشمالي\nخلدا\nخلدا › الغربي' }));
    expect(result).toEqual({ created: 3, skipped: 3 }); // «النخيل» once, «خلدا» twice
    const nakheel = state().areas.find((a) => a.name === 'النخيل')!;
    expect(state().areas.find((a) => a.name === 'الشمالي')?.parentId).toBe(nakheel.id);
    expect(state().areas.find((a) => a.name === 'الغربي')?.parentId).toBe('a-khalda');
  });
});

describe('merchant coverage (not a price)', () => {
  it('validates merchant and areas', () => {
    const { state } = newStore();
    expect(failureOf(state().setMerchantCoverage('m-nobody', ['a-khalda'], true))).toBe('التاجر غير موجود');
    expect(failureOf(state().setMerchantCoverage('m-sanabel', ['a-nowhere'], true))).toBe('منطقة غير موجودة');
  });

  it('cannot enable a stopped area', () => {
    const { state } = newStore();
    valueOf(state().setServiceAreaStatus('a-abdoun', false));
    expect(failureOf(state().setMerchantCoverage('m-sanabel', ['a-abdoun'], true))).toBe('لا يمكن تفعيل منطقة متوقفة للتاجر');
  });

  it('enabling is idempotent and counts only real changes; disabling removes', () => {
    const { state } = newStore();
    const id = valueOf(state().createZone(zone()));
    expect(valueOf(state().setMerchantCoverage('m-sanabel', [id, id], true))).toEqual({ changed: 1 });
    expect(valueOf(state().setMerchantCoverage('m-sanabel', [id], true))).toEqual({ changed: 0 });
    expect(state().prices.some((p) => p.merchantId === 'm-sanabel' && p.areaId === id)).toBe(false);
    expect(valueOf(state().setMerchantCoverage('m-sanabel', [id], false))).toEqual({ changed: 1 });
  });
});

describe('delivery routes (no pricing effect)', () => {
  const route = (over: Record<string, unknown> = {}) => ({ governorateId: 'amman', originAreaId: 'a-khalda', destinationAreaId: 'a-abdoun', ...over });

  it.each([
    [{ governorateId: 'x' }, 'اختر المحافظة أولاً'],
    [{ originAreaId: 'a-nowhere' }, 'اختر منطقة الانطلاق'],
    [{ destinationAreaId: 'a-nowhere' }, 'اختر منطقة الوصول'],
    [{ governorateId: 'irbid' }, 'المنطقتان يجب أن تكونا ضمن المحافظة المختارة'],
    [{ destinationAreaId: 'a-khalda' }, 'اختر منطقة وصول مختلفة عن منطقة الانطلاق'],
  ])('rejects %j', (over, message) => {
    const { state } = newStore();
    expect(failureOf(state().createRoute(route(over)))).toBe(message);
  });

  it('creates once, refuses duplicates, and removes', () => {
    const { state } = newStore();
    const prices = state().prices.length;
    const id = valueOf(state().createRoute(route()));
    expect(failureOf(state().createRoute(route()))).toContain('موجود مسبقاً');
    expect(state().prices.length).toBe(prices);
    valueOf(state().removeRoute(id));
    expect(failureOf(state().removeRoute(id))).toBe('المسار غير موجود');
  });

  it('an area used by a route cannot move governorate', () => {
    const { state } = newStore();
    valueOf(state().createRoute(route({ destinationAreaId: 'a-sweifieh' }))); // no merchant is located in Sweifieh
    expect(failureOf(state().updateZone('a-sweifieh', { governorateId: 'irbid', cityId: 'irbid' }))).toContain('مرتبطة بمسارات توصيل');
  });
});

describe('merchant area prices', () => {
  it('rejects zero, negative and fractional fils, unknown merchant or area', () => {
    const { state } = newStore();
    for (const bad of [0, -100, 1.5]) expect(failureOf(state().setMerchantAreaPrice('m-sanabel', 'a-abdoun', bad))).toBe('أدخل رسوم توصيل صالحة أكبر من صفر');
    expect(failureOf(state().setMerchantAreaPrice('m-nobody', 'a-abdoun', 1_000))).toBe('التاجر غير موجود');
    expect(failureOf(state().setMerchantAreaPrice('m-sanabel', 'a-nowhere', 1_000))).toBe('المنطقة غير موجودة');
  });

  it('adds, updates and removes a price', () => {
    const { state } = newStore();
    const find = () => state().prices.find((p) => p.merchantId === 'm-sanabel' && p.areaId === 'a-abdoun');
    expect(find()).toBeUndefined();
    valueOf(state().setMerchantAreaPrice('m-sanabel', 'a-abdoun', 2_000));
    expect(find()).toMatchObject({ price: 2_000, status: 'active' });
    valueOf(state().setMerchantAreaPrice('m-sanabel', 'a-abdoun', 2_250));
    expect(find()?.price).toBe(2_250);
    valueOf(state().setMerchantAreaPrice('m-sanabel', 'a-abdoun', null));
    expect(find()).toBeUndefined();
    valueOf(state().setMerchantAreaPrice('m-sanabel', 'a-abdoun', null)); // removing nothing is fine
  });

  it('price status needs an existing price', () => {
    const { state } = newStore();
    expect(failureOf(state().setMerchantAreaPriceStatus('m-sanabel', 'a-abdoun', true))).toBe('لا يوجد سعر لهذه المنطقة');
    valueOf(state().setMerchantAreaPrice('m-sanabel', 'a-abdoun', 2_000));
    valueOf(state().setMerchantAreaPriceStatus('m-sanabel', 'a-abdoun', false));
    expect(state().prices.find((p) => p.merchantId === 'm-sanabel' && p.areaId === 'a-abdoun')?.status).toBe('inactive');
  });

  it('copying pricing needs two different, existing merchants', () => {
    const { state } = newStore();
    expect(failureOf(state().copyMerchantPricing('m-hail', 'm-hail', 'fill_missing'))).toBe('لا يمكن نسخ تسعيرة المتجر إلى نفسه');
    expect(failureOf(state().copyMerchantPricing('m-hail', 'm-nobody', 'fill_missing'))).toBe('التاجر غير موجود');
  });
});
