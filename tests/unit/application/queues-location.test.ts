import { describe, expect, it } from 'vitest';
import { dispatchQueues } from '@/application/dispatchQueues';
import { isUnchangedLegacyLocation, pickupAddressLabel, pickupLocationError, PICKUP_REQUIRED } from '@/application/merchantLocation';
import type { DeliveryOrder, Merchant } from '@/domain/types';
import { makeArea, SQUARE } from '../../fixtures';

const o = (id: string, over: Partial<DeliveryOrder>): DeliveryOrder => ({ id, createdAt: 0, requestType: 'immediate', status: 'pending_dispatch', ...over }) as DeliveryOrder;

describe('dispatchQueues (one list per order)', () => {
  const orders = [
    o('sch-late', { requestType: 'scheduled', scheduledPickupAt: 2_000 }),
    o('sch-early', { requestType: 'scheduled', scheduledPickupAt: 1_000, status: 'offered_privately' }),
    o('sch-accepted', { requestType: 'scheduled', status: 'accepted' }),
    o('exp-new', { status: 'dispatch_expired', createdAt: 20 }),
    o('exp-old', { status: 'dispatch_expired', createdAt: 10 }),
    o('wait', { status: 'pending_dispatch', createdAt: 5 }),
    o('offer-pub', { status: 'awaiting_captain', createdAt: 3 }),
    o('offer-priv', { status: 'offered_privately', createdAt: 1 }),
    o('done', { status: 'delivered' }),
  ];
  const q = dispatchQueues(orders);

  it('scheduled orders sort by pickup time and include their private offer', () => {
    expect(q.scheduled.map((x) => x.id)).toEqual(['sch-early', 'sch-late']);
  });

  it('immediate orders split by status, oldest first', () => {
    expect(q.intervention.map((x) => x.id)).toEqual(['exp-old', 'exp-new']);
    expect(q.waiting.map((x) => x.id)).toEqual(['wait']);
    expect(q.offering.map((x) => x.id)).toEqual(['offer-priv', 'offer-pub']);
  });

  it('no order appears in two lists; accepted and finished orders appear in none', () => {
    const ids = [...q.scheduled, ...q.intervention, ...q.waiting, ...q.offering].map((x) => x.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect(ids).not.toContain('sch-accepted');
    expect(ids).not.toContain('done');
  });

  it('a scheduled order without a pickup time sorts first', () => {
    const r = dispatchQueues([o('a', { requestType: 'scheduled', scheduledPickupAt: 5 }), o('b', { requestType: 'scheduled' })]);
    expect(r.scheduled.map((x) => x.id)).toEqual(['b', 'a']);
  });
});

describe('merchant pickup location (City → Area → pin)', () => {
  const plain = makeArea({ id: 'a-plain', name: 'النخيل' });
  const legacy = makeArea({ id: 'a-legacy', name: 'خلدا', polygon: SQUARE });
  const areas = [plain, legacy];
  const input = (over = {}) => ({ cityId: 'amman', areaId: 'a-legacy', pickup: { lat: 31.95, lng: 35.9 }, ...over });

  it.each([
    [{ cityId: 'nowhere' }, 'اختر المدينة'],
    [{ areaId: 'a-nowhere' }, 'اختر منطقة تابعة للمدينة المختارة'],
    [{ cityId: 'irbid' }, 'اختر منطقة تابعة للمدينة المختارة'],
    [{ pickup: { lat: 99, lng: 0 } }, PICKUP_REQUIRED],
    [{ pickup: { lat: 0, lng: 0 } }, PICKUP_REQUIRED],
  ])('rejects %j', (over, message) => {
    expect(pickupLocationError(areas, input(over))).toBe(message);
  });

  it('a merchant may be registered anywhere: inside or outside the area boundary, or far away', () => {
    expect(pickupLocationError(areas, input())).toBeNull();
    expect(pickupLocationError(areas, input({ pickup: { lat: 31.0, lng: 35.0 } }))).toBeNull();
    expect(pickupLocationError(areas, input({ pickup: { lat: 29.53, lng: 35.0 } }))).toBeNull(); // Aqaba
    expect(pickupLocationError(areas, input({ areaId: 'a-plain', pickup: { lat: 31.0, lng: 35.0 } }))).toBeNull();
  });

  it('a legacy text-address merchant is unchanged only when nothing moved', () => {
    const m = { areaId: null, cityId: null, pickup: { lat: 1, lng: 2 } } as unknown as Merchant;
    expect(isUnchangedLegacyLocation(m, { cityId: null, areaId: null, pickup: { lat: 1, lng: 2 } })).toBe(true);
    expect(isUnchangedLegacyLocation(m, { cityId: null, areaId: null, pickup: { lat: 1, lng: 3 } })).toBe(false);
    expect(isUnchangedLegacyLocation(undefined, { cityId: null, areaId: null, pickup: { lat: 1, lng: 2 } })).toBe(false);
  });

  it('address label: kept when City/Area are unchanged, derived otherwise', () => {
    const m = { areaId: 'a-plain', cityId: 'amman', address: 'نص قديم' } as unknown as Merchant;
    expect(pickupAddressLabel(areas, m, { cityId: 'amman', areaId: 'a-plain', pickup: { lat: 0, lng: 0 } })).toBe('نص قديم');
    expect(pickupAddressLabel(areas, m, { cityId: 'amman', areaId: 'a-legacy', pickup: { lat: 0, lng: 0 } })).toBe('خلدا، عمّان');
    expect(pickupAddressLabel(areas, undefined, { cityId: 'amman', areaId: 'a-nowhere', pickup: { lat: 0, lng: 0 } })).toBe('، عمّان');
  });
});
