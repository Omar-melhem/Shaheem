import { describe, expect, it } from 'vitest';
import { FRESHNESS_LABEL, locationFreshness } from '@/domain/location';
import { describeReasons, evaluateEligibility, INELIGIBILITY_LABEL } from '@/domain/eligibility';
import { makeCaptain, T0 } from '../../fixtures';

describe('locationFreshness (GPS only during an active delivery)', () => {
  const STALE_SEC = 60;
  const trip = (recordedAt: number, activeOrderId = 'o-1') =>
    makeCaptain({ lastLocation: { position: { lat: 31.9, lng: 35.9 }, recordedAt, source: 'trip_simulated', activeOrderId } });

  it('returns none when the captain has no location', () => {
    expect(locationFreshness(makeCaptain({ lastLocation: undefined }), T0, STALE_SEC, undefined)).toBe('none');
  });

  it('is live for a fresh trip fix that belongs to the active order', () => {
    expect(locationFreshness(trip(T0 - 30_000), T0, STALE_SEC, 'o-1')).toBe('live');
  });

  it('is stale when the trip fix is older than the threshold', () => {
    expect(locationFreshness(trip(T0 - 61_000), T0, STALE_SEC, 'o-1')).toBe('stale');
  });

  it('is stale when the trip fix belongs to another order', () => {
    expect(locationFreshness(trip(T0, 'o-other'), T0, STALE_SEC, 'o-1')).toBe('stale');
  });

  it('never claims live outside a trip: idle demo position is "demo"', () => {
    expect(locationFreshness(makeCaptain(), T0, STALE_SEC, undefined)).toBe('demo');
  });

  it('a trip fix without an active order is only the last known position', () => {
    expect(locationFreshness(trip(T0), T0, STALE_SEC, undefined)).toBe('last_known');
  });

  it('has an Arabic label for every state', () => {
    for (const s of ['live', 'stale', 'last_known', 'demo', 'none'] as const) expect(FRESHNESS_LABEL[s]).toBeTruthy();
  });
});

describe('evaluateEligibility', () => {
  const ctx = { hasActiveDelivery: false, balance: 5_000, walletThreshold: 1_000 };

  it('accepts an active, available captain with balance and a location', () => {
    expect(evaluateEligibility(makeCaptain(), ctx)).toEqual({ eligible: true, reasons: [] });
  });

  it('collects every reason at once, in a stable order', () => {
    const c = makeCaptain({ status: 'inactive', availability: 'offline', lastLocation: undefined });
    expect(evaluateEligibility(c, { hasActiveDelivery: true, balance: 0, walletThreshold: 1_000 }).reasons).toEqual([
      'inactive_account',
      'offline',
      'busy',
      'insufficient_wallet',
      'no_location',
    ]);
  });

  it('rejects a balance below the threshold', () => {
    expect(evaluateEligibility(makeCaptain(), { ...ctx, balance: 999 }).reasons).toEqual(['insufficient_wallet']);
  });

  it('accepts a balance exactly at the threshold', () => {
    expect(evaluateEligibility(makeCaptain(), { ...ctx, balance: 1_000 }).eligible).toBe(true);
  });

  it('rejects a zero balance even with a zero threshold', () => {
    expect(evaluateEligibility(makeCaptain(), { ...ctx, balance: 0, walletThreshold: 0 }).reasons).toEqual(['insufficient_wallet']);
  });
});

describe('describeReasons', () => {
  it('joins Arabic labels with the Arabic comma', () => {
    expect(describeReasons(['offline', 'busy'])).toBe(`${INELIGIBILITY_LABEL.offline}، ${INELIGIBILITY_LABEL.busy}`);
  });

  it('adds the demo threshold to the wallet reason when given', () => {
    expect(describeReasons(['insufficient_wallet'], 1_500)).toBe(`${INELIGIBILITY_LABEL.insufficient_wallet} (الحد التجريبي 1.50 د.أ)`);
  });

  it('returns an empty string for no reasons', () => {
    expect(describeReasons([])).toBe('');
  });
});
