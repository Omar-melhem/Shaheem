import { describe, expect, it } from 'vitest';
import { commissionFils, parsePercentToBp, formatPercentInput } from '@/domain/commission';
import {
  ALL_OFFERED_REASON,
  DISPATCH_ROUNDS,
  MAX_DISPATCH_RADIUS_M,
  NO_CANDIDATE_REASON,
  OUT_OF_RANGE_REASON,
  describeRound,
  roundsEndedReason,
  selectRoundCandidates,
  type RankedCaptain,
} from '@/domain/dispatch';
import { polygonCovers } from '@/domain/geo';
import { AREA_HAS_NO_BOUNDARY, PIN_INVALID, destinationPinError, matchAreaForPin, pinOutsideAreaError } from '@/domain/destination';
import {
  IDLE_STALE_AFTER_SEC,
  isPinnedOnLiveMap,
  liveMapPresence,
  locationFreshness,
  locationReportIntervalSec,
} from '@/domain/location';
import { MAX_ORDER_TOTAL_FILS, ORDER_TOTAL_ERROR, ORDER_TOTAL_PRECISION_ERROR, ORDER_TOTAL_TOO_LARGE, isValidOrderTotal, parseOrderTotal } from '@/domain/orderTotal';
import { MAX_TOPUP_FILS, TOPUP_AMOUNT_ERROR, TOPUP_LIMIT_ERROR, heldCommission, ledgerBalance, realizedCommission, topUpAmountError } from '@/domain/wallet';
import type { DeliveryOrder, WalletTransaction } from '@/domain/types';
import { SQUARE, T0, makeArea, makeCaptain } from '../../fixtures';

const tx = (over: Partial<WalletTransaction>): WalletTransaction => ({
  id: 'tx', captainId: 'c-1', type: 'recharge', amount: 0, createdAt: T0, actor: { role: 'admin', name: 'admin' }, ...over,
});
const order = (over: Partial<DeliveryOrder>) => ({ id: 'o', captainId: 'c-1', status: 'accepted', ...over }) as DeliveryOrder;

describe('1 · commission and wallet ledger', () => {
  it('20% of a 5.000 JOD fee is exactly 1.000 JOD (integer fils)', () => {
    expect(commissionFils(5_000, 2000)).toBe(1_000);
    expect(commissionFils(1_250, 2000)).toBe(250);
    expect(commissionFils(1_255, 2000)).toBe(251); // 251.0 → half up only where it applies
  });

  it('top-up: positive whole fils up to 5.000 JOD per transaction', () => {
    expect(MAX_TOPUP_FILS).toBe(5_000);
    expect(topUpAmountError(5_000)).toBeNull();
    expect(topUpAmountError(1)).toBeNull();
    expect(topUpAmountError(5_001)).toBe(TOPUP_LIMIT_ERROR);
    for (const bad of [0, -1, 1.5, Number.NaN]) expect(topUpAmountError(bad)).toBe(TOPUP_AMOUNT_ERROR);
  });

  it('balance is the signed ledger sum; revenue counts commission debits only, never top-ups', () => {
    const ledger = [tx({ amount: 5_000 }), tx({ type: 'commission_debit', amount: -1_000, orderId: 'o1' }), tx({ captainId: 'c-2', amount: 3_000 })];
    expect(ledgerBalance(ledger, 'c-1')).toBe(4_000);
    expect(realizedCommission(ledger)).toBe(1_000);
    expect(realizedCommission([tx({ amount: 5_000 })])).toBe(0);
  });

  it('a hold is the snapshot on accepted, undelivered orders — not delivered, cancelled or legacy ones', () => {
    const orders = [
      order({ id: 'a', status: 'accepted', commissionFils: 300 }),
      order({ id: 'b', status: 'on_the_way', commissionFils: 200 }),
      order({ id: 'c', status: 'delivered', commissionFils: 999 }),
      order({ id: 'd', status: 'cancelled', commissionFils: 999 }),
      order({ id: 'e', status: 'picked_up' }), // accepted before commission existed
      order({ id: 'f', status: 'accepted', commissionFils: 999, captainId: 'c-2' }),
    ];
    expect(heldCommission(orders, 'c-1')).toBe(500);
  });

  it('a typed rate becomes basis points without floats, within 0–100%', () => {
    expect(parsePercentToBp('20')).toBe(2000);
    expect(parsePercentToBp('12.5')).toBe(1250);
    expect(parsePercentToBp('٢٠')).toBe(2000);
    expect(parsePercentToBp(' 7,25 % ')).toBe(725);
    expect(parsePercentToBp('100')).toBe(10_000);
    expect(parsePercentToBp('0')).toBe(0);
    for (const bad of ['', '-5', '100.01', '101', '1e2', '12.345', 'abc']) expect(parsePercentToBp(bad)).toBeNull();
    expect(formatPercentInput(1250)).toBe('12.5');
  });
});

describe('2 · dispatch rounds: 3 within 5 km → next 3 within 10 km → all left within 10 km', () => {
  const ranked = (km: number[]): RankedCaptain[] => km.map((k, i) => ({ captain: makeCaptain({ id: `c${i}` }), distanceMeters: k * 1000 }));

  it('the policy is three 5/10/10 km rounds and nobody beyond 10 km', () => {
    expect(DISPATCH_ROUNDS.map((r) => [r.radiusMeters, r.maxCaptains])).toEqual([[5_000, 3], [10_000, 3], [10_000, null]]);
    expect(MAX_DISPATCH_RADIUS_M).toBe(10_000);
    expect(describeRound(DISPATCH_ROUNDS[0])).toBe('أقرب 3 كباتن مؤهلين ضمن 5 كم');
    expect(describeRound(DISPATCH_ROUNDS[2])).toBe('كل الكباتن المؤهلين المتبقين ضمن 10 كم');
  });

  it('round 1 takes the 3 nearest within 5 km; exactly 5 km is inside', () => {
    const r = ranked([1, 2, 4, 5, 5.001]);
    expect(selectRoundCandidates(r, DISPATCH_ROUNDS[0], new Set()).map((x) => x.captain.id)).toEqual(['c0', 'c1', 'c2']);
    expect(selectRoundCandidates(r, DISPATCH_ROUNDS[0], new Set(['c0', 'c1', 'c2'])).map((x) => x.captain.id)).toEqual(['c3']);
  });

  it('later rounds skip anyone already offered and stop at 10 km', () => {
    const r = ranked([1, 2, 3, 6, 7, 8, 9, 10, 10.5]);
    const offered = new Set(['c0', 'c1', 'c2']);
    expect(selectRoundCandidates(r, DISPATCH_ROUNDS[1], offered).map((x) => x.captain.id)).toEqual(['c3', 'c4', 'c5']);
    ['c3', 'c4', 'c5'].forEach((id) => offered.add(id));
    expect(selectRoundCandidates(r, DISPATCH_ROUNDS[2], offered).map((x) => x.captain.id)).toEqual(['c6', 'c7']);
  });

  it('end reasons: nobody eligible / nobody in range / everyone in range offered', () => {
    expect(roundsEndedReason(0, 0)).toBe(NO_CANDIDATE_REASON);
    expect(roundsEndedReason(4, 0)).toBe(OUT_OF_RANGE_REASON);
    expect(roundsEndedReason(4, 2)).toBe(ALL_OFFERED_REASON);
    expect(OUT_OF_RANGE_REASON).toContain('10 كم');
  });
});

describe('3/4 · live map presence and location cadence', () => {
  const base = { accountActive: true, available: true, hasActiveDelivery: false };

  it('reporting: 60 s when Available and idle, 30 s on a delivery, none when offline or suspended', () => {
    expect(locationReportIntervalSec(base)).toBe(60);
    expect(locationReportIntervalSec({ ...base, hasActiveDelivery: true })).toBe(30);
    expect(locationReportIntervalSec({ ...base, available: false })).toBeNull();
    expect(locationReportIntervalSec({ ...base, accountActive: false })).toBeNull();
  });

  it('an idle report is fresh for 90 s, then only a last-known position', () => {
    const c = makeCaptain({ lastLocation: { position: { lat: 31.9, lng: 35.9 }, recordedAt: T0, source: 'idle_report' } });
    expect(locationFreshness(c, T0 + IDLE_STALE_AFTER_SEC * 1000, 20, undefined)).toBe('reported');
    expect(locationFreshness(c, T0 + IDLE_STALE_AFTER_SEC * 1000 + 1, 20, undefined)).toBe('last_known');
  });

  it('pins: Available with a recent report and delivering with live GPS; stale delivery is listed, not pinned', () => {
    expect(liveMapPresence({ ...base, freshness: 'reported' })).toBe('available');
    expect(liveMapPresence({ ...base, freshness: 'demo' })).toBe('hidden');
    expect(liveMapPresence({ ...base, freshness: 'last_known' })).toBe('hidden');
    expect(liveMapPresence({ ...base, available: false, freshness: 'reported' })).toBe('hidden');
    expect(liveMapPresence({ ...base, accountActive: false, freshness: 'reported' })).toBe('hidden');
    expect(liveMapPresence({ ...base, hasActiveDelivery: true, freshness: 'live' })).toBe('delivering');
    expect(liveMapPresence({ ...base, hasActiveDelivery: true, freshness: 'stale' })).toBe('delivering_stale');
    expect(isPinnedOnLiveMap('delivering_stale')).toBe(false);
    expect(isPinnedOnLiveMap('available') && isPinnedOnLiveMap('delivering')).toBe(true);
  });
});

describe('9 · optional «مجموع الطلب»', () => {
  it('blank is absent; valid amounts are integer fils; zero is allowed', () => {
    expect(parseOrderTotal('')).toEqual({ ok: true, fils: undefined });
    expect(parseOrderTotal('   ')).toEqual({ ok: true, fils: undefined });
    expect(parseOrderTotal('12.5')).toEqual({ ok: true, fils: 12_500 });
    expect(parseOrderTotal('١٢٫٥٠٠')).toEqual({ ok: true, fils: 12_500 });
    expect(parseOrderTotal('0')).toEqual({ ok: true, fils: 0 });
  });

  it('refuses negatives, exponents, text, a 4th decimal and absurd values', () => {
    for (const bad of ['-1', '1e3', 'abc', 'NaN']) expect(parseOrderTotal(bad)).toEqual({ ok: false, error: ORDER_TOTAL_ERROR });
    expect(parseOrderTotal('1.0005')).toEqual({ ok: false, error: ORDER_TOTAL_PRECISION_ERROR });
    expect(parseOrderTotal('100000')).toEqual({ ok: false, error: ORDER_TOTAL_TOO_LARGE });
    expect(isValidOrderTotal(undefined) && isValidOrderTotal(0) && isValidOrderTotal(MAX_ORDER_TOTAL_FILS)).toBe(true);
    expect(isValidOrderTotal(-1) || isValidOrderTotal(1.5) || isValidOrderTotal(MAX_ORDER_TOTAL_FILS + 1)).toBe(false);
  });
});

describe('10 · customer pin anywhere inside the priced area, boundary included', () => {
  const area = makeArea({ name: 'أم أذينة', polygon: SQUARE });

  it('inside, on an edge and on a vertex are covered; outside is not', () => {
    expect(polygonCovers(SQUARE, { lat: 31.95, lng: 35.9 })).toBe(true);
    expect(polygonCovers(SQUARE, { lat: 31.94, lng: 35.9 })).toBe(true); // bottom edge
    expect(polygonCovers(SQUARE, { lat: 31.95, lng: 35.91 })).toBe(true); // right edge
    expect(polygonCovers(SQUARE, SQUARE[2])).toBe(true); // vertex
    expect(polygonCovers(SQUARE, { lat: 31.9399, lng: 35.9 })).toBe(false);
    expect(polygonCovers([], { lat: 31.95, lng: 35.9 })).toBe(false);
  });

  it('the pin error names the area only when the point is truly outside', () => {
    expect(destinationPinError(area, { lat: 31.95, lng: 35.9 })).toBeNull();
    expect(destinationPinError(area, { lat: 31.94, lng: 35.895 })).toBeNull();
    expect(destinationPinError(area, { lat: 31.93, lng: 35.9 })).toBe(pinOutsideAreaError(area));
    expect(pinOutsideAreaError(area)).toContain('الموقع خارج منطقة التوصيل المحددة');
    expect(destinationPinError(area, { lat: 0, lng: 0 })).toBe(PIN_INVALID);
    expect(destinationPinError(area, { lat: 95, lng: 0 })).toBe(PIN_INVALID);
    expect(destinationPinError(makeArea(), { lat: 31.95, lng: 35.9 })).toBe(AREA_HAS_NO_BOUNDARY);
  });

  it('a pin on a border shared by two areas is ambiguous, never guessed', () => {
    const east = makeArea({ id: 'east', polygon: SQUARE.map((p) => ({ ...p, lng: p.lng + 0.02 })) });
    const west = makeArea({ id: 'west', polygon: SQUARE });
    expect(matchAreaForPin([west, east], { lat: 31.95, lng: 35.91 })).toEqual({ kind: 'ambiguous' });
    expect(matchAreaForPin([west, east], { lat: 31.95, lng: 35.9 })).toEqual({ kind: 'one', area: west });
    expect(matchAreaForPin([west, east], { lat: 30, lng: 30 })).toEqual({ kind: 'none' });
  });
});
