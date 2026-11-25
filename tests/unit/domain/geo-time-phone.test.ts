import { describe, expect, it } from 'vitest';
import { formatDistance, haversineMeters, isValidLatLng, moveTowards, pointInPolygon, polygonCentroid } from '@/domain/geo';
import { ammanDayKey, ammanWallTimeToEpoch, formatAmmanDateTime, formatAmmanTime, lastThreeAmmanDays } from '@/domain/time';
import { isValidOptionalPhone, isValidPhone, normalizePhone } from '@/domain/phone';
import { destinationPinError, hasAreaBoundary, isAreaOnly, AREA_HAS_NO_BOUNDARY } from '@/domain/destination';
import { isAutoDispatchEligible, rankByProximity } from '@/domain/dispatch';
import { CANCELLABLE_STATUSES, CAPTAIN_NEXT_STATUS, isActiveDelivery, isInQueue, isOffering, ORDER_STATUS_LABEL } from '@/domain/orderStatus';
import { makeArea, makeCaptain, SQUARE } from '../../fixtures';

describe('geo', () => {
  it('validates coordinates', () => {
    expect(isValidLatLng({ lat: 31.9, lng: 35.9 })).toBe(true);
    expect(isValidLatLng({ lat: 91, lng: 0 })).toBe(false);
    expect(isValidLatLng({ lat: 0, lng: -181 })).toBe(false);
    expect(isValidLatLng({ lat: Number.NaN, lng: 0 })).toBe(false);
    expect(isValidLatLng(null)).toBe(false);
  });

  it('haversine: one degree of latitude is about 111 km', () => {
    expect(haversineMeters({ lat: 0, lng: 0 }, { lat: 1, lng: 0 })).toBeCloseTo(111_195, -2);
    expect(haversineMeters({ lat: 31.9, lng: 35.9 }, { lat: 31.9, lng: 35.9 })).toBe(0);
  });

  it('point in polygon', () => {
    expect(pointInPolygon({ lat: 31.95, lng: 35.9 }, SQUARE)).toBe(true);
    expect(pointInPolygon({ lat: 32.5, lng: 35.9 }, SQUARE)).toBe(false);
  });

  it('moveTowards stops at the target and never overshoots', () => {
    const from = { lat: 31.9, lng: 35.9 };
    const to = { lat: 31.91, lng: 35.9 };
    expect(moveTowards(from, to, 10_000)).toEqual(to);
    const step = moveTowards(from, to, 500);
    expect(haversineMeters(from, step)).toBeCloseTo(500, -1);
    expect(moveTowards(to, to, 5)).toEqual(to);
  });

  it('centroid of a square is its centre; empty polygon does not divide by zero', () => {
    const c = polygonCentroid(SQUARE);
    expect(c.lat).toBeCloseTo(31.95);
    expect(c.lng).toBeCloseTo(35.9);
    expect(polygonCentroid([])).toEqual({ lat: 0, lng: 0 });
  });

  it('formats distances in metres or kilometres', () => {
    expect(formatDistance(420.4)).toBe('420 م');
    expect(formatDistance(2_350)).toBe('2.4 كم');
  });
});

describe('Amman time', () => {
  it('Amman 10:00 is 07:00 UTC (UTC+3)', () => {
    expect(ammanWallTimeToEpoch('2026-11-09', '10:00')).toBe(Date.UTC(2026, 10, 9, 7, 0));
  });

  it.each([
    ['2026-02-31', '10:00'],
    ['2026-13-01', '10:00'],
    ['2026-11-09', '24:00'],
    ['2026-11-09', '10:60'],
    ['09/11/2026', '10:00'],
    ['2026-11-09', '9:00'],
  ])('rejects %s %s', (d, t) => {
    expect(ammanWallTimeToEpoch(d, t)).toBeNull();
  });

  it('day key follows Amman, not UTC (22:30 UTC is already the next day)', () => {
    expect(ammanDayKey(Date.UTC(2026, 10, 9, 22, 30))).toBe('2026-11-10');
  });

  it('last three days cross month boundaries', () => {
    expect(lastThreeAmmanDays(Date.UTC(2026, 11, 1, 9))).toEqual(['2026-12-01', '2026-11-30', '2026-11-29']);
  });

  it('formats in Amman time with Latin digits', () => {
    const ts = Date.UTC(2026, 10, 9, 12, 30); // 15:30 Amman
    expect(formatAmmanTime(ts)).toMatch(/3:30/);
    expect(formatAmmanDateTime(ts)).toMatch(/3:30/);
  });
});

describe('phone (exactly 10 digits)', () => {
  it('normalises Arabic-Indic and Persian digits and drops separators', () => {
    expect(normalizePhone('٠٧٩ ١٢٣-٤٥٦٧')).toBe('0791234567');
    expect(normalizePhone('۰۷۹۱۲۳۴۵۶۷')).toBe('0791234567');
    expect(normalizePhone('+962 (79) 123')).toBe('96279123');
  });

  it('requires exactly ten digits', () => {
    expect(isValidPhone('0791234567')).toBe(true);
    expect(isValidPhone('079123456')).toBe(false);
    expect(isValidPhone('07912345678')).toBe(false);
  });

  it('optional phone: blank is valid, a supplied value must be ten digits', () => {
    expect(isValidOptionalPhone(undefined)).toBe(true);
    expect(isValidOptionalPhone('   ')).toBe(true);
    expect(isValidOptionalPhone('123')).toBe(false);
  });
});

describe('destination', () => {
  it('only legacy areas have a boundary', () => {
    expect(hasAreaBoundary(makeArea())).toBe(false);
    expect(hasAreaBoundary(makeArea({ polygon: SQUARE }))).toBe(true);
  });

  it('a pin outside a legacy boundary is an error that names the area; inside is fine', () => {
    const legacy = makeArea({ polygon: SQUARE, name: 'خلدا' });
    expect(destinationPinError(legacy, { lat: 32.5, lng: 35.9 })).toContain('«خلدا»');
    expect(destinationPinError(legacy, { lat: 31.95, lng: 35.9 })).toBeNull();
  });

  it('an area without a boundary cannot verify a pin, so the pin is refused (never the whole city)', () => {
    expect(destinationPinError(makeArea(), { lat: 10, lng: 10 })).toBe(AREA_HAS_NO_BOUNDARY);
  });

  it('area-only destinations have no coordinates', () => {
    expect(isAreaOnly({ areaId: 'a', label: 'x' } as never)).toBe(true);
    expect(isAreaOnly({ areaId: 'a', label: 'x', position: { lat: 1, lng: 1 } } as never)).toBe(false);
  });
});

describe('dispatch rules', () => {
  it('scheduled orders are never auto-dispatched', () => {
    expect(isAutoDispatchEligible({ requestType: 'scheduled' })).toBe(false);
    expect(isAutoDispatchEligible({ requestType: 'immediate' })).toBe(true);
    expect(isAutoDispatchEligible({})).toBe(true);
  });

  it('ranks captains with a location by distance to the pickup', () => {
    const pickup = { lat: 31.95, lng: 35.9 };
    const near = makeCaptain({ id: 'near', lastLocation: { position: { lat: 31.951, lng: 35.9 }, recordedAt: 0, source: 'demo_idle' } });
    const far = makeCaptain({ id: 'far', lastLocation: { position: { lat: 32.1, lng: 35.9 }, recordedAt: 0, source: 'demo_idle' } });
    const none = makeCaptain({ id: 'none', lastLocation: undefined });
    expect(rankByProximity([far, none, near], pickup).map((r) => r.captain.id)).toEqual(['near', 'far']);
  });
});

describe('order status sets', () => {
  it('every status has an Arabic label', () => {
    for (const label of Object.values(ORDER_STATUS_LABEL)) expect(label).toMatch(/[؀-ۿ]/);
  });

  it('only pre-acceptance states are cancellable', () => {
    expect(CANCELLABLE_STATUSES).toEqual(['pending_dispatch', 'dispatch_expired', 'awaiting_captain', 'offered_privately']);
    expect(CANCELLABLE_STATUSES).not.toContain('accepted');
  });

  it('captain stages advance one step at a time and end at delivered', () => {
    let s: keyof typeof CAPTAIN_NEXT_STATUS | undefined = 'accepted';
    const path: string[] = [];
    while (s) { path.push(s); s = CAPTAIN_NEXT_STATUS[s]; }
    expect(path).toEqual(['accepted', 'heading_to_pickup', 'picked_up', 'on_the_way', 'delivered']);
  });

  it('classifies statuses', () => {
    expect(isActiveDelivery('picked_up')).toBe(true);
    expect(isInQueue('dispatch_expired')).toBe(true);
    expect(isOffering('offered_privately')).toBe(true);
    expect(isActiveDelivery('delivered')).toBe(false);
  });
});
