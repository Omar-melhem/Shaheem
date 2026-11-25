// @vitest-environment jsdom
import { afterEach, describe, expect, it, vi } from 'vitest';
import { createApplicationStore } from '@/application/store';
import type { AppData } from '@/application/data';
import { commissionRevenue } from '@/application/dashboard';
import { settleDeliveredCommission } from '@/application/walletLedger';
import { commissionFils, COMMISSION_RATE_ERROR } from '@/domain/commission';
import { OUT_OF_RANGE_REASON, MAX_DISPATCH_ROUNDS } from '@/domain/dispatch';
import { heldCommission } from '@/domain/wallet';
import { locationFreshness } from '@/domain/location';
import { ORDER_TOTAL_ERROR } from '@/domain/orderTotal';
import type { Captain, WalletTransaction } from '@/domain/types';
import { createSeedData } from '@/infrastructure/seed';
import { browserRepository, migrateAppData, STORAGE_KEY } from '@/infrastructure/browserState';
import { failureOf, memoryRepository, newStore, valueOf } from './storeHarness';

const PICKUP = { lat: 32.02, lng: 35.86 }; // m-sanabel
const M_PER_DEG_LAT = 111_195;
/** A Captain `km` north of the Merchant, eligible, with 5 JOD in the wallet. */
const captainAt = (id: string, km: number): Captain => ({
  id, fullName: id, phone: '0790000000', username: id, password: 'secret1', status: 'active', availability: 'available', gpsSignal: 'ok', createdAt: 0,
  lastLocation: { position: { lat: PICKUP.lat + (km * 1000) / M_PER_DEG_LAT, lng: PICKUP.lng }, recordedAt: Date.now(), source: 'demo_idle' },
});

/** Seed data with only the given Captains (each funded), so distances are exact. */
function storeWith(kms: Record<string, number>) {
  const seed = (): AppData => {
    const d = createSeedData();
    d.captains = Object.entries(kms).map(([id, km]) => captainAt(id, km));
    d.walletTx = d.captains.map((c, i) => ({ id: `tx-${i}`, captainId: c.id, type: 'recharge', amount: 5_000, createdAt: 0, actor: { role: 'admin', name: 'admin' } }));
    return d;
  };
  const store = createApplicationStore(seed, memoryRepository());
  return { state: () => store.getState() };
}
const newOrder = (s: { state: () => ReturnType<ReturnType<typeof newStore>['state']> }) =>
  valueOf(s.state().createOrder('m-sanabel', { areaId: 'a-khalda' })).id;
const pending = (s: ReturnType<typeof storeWith>, id: string) => s.state().offers.filter((o) => o.orderId === id && o.status === 'pending');
const expireRound = (s: ReturnType<typeof storeWith>, id: string) => {
  const until = Math.max(...pending(s, id).map((o) => o.expiresAt));
  s.state().tick(until + 1);
};

afterEach(() => vi.useRealTimers());

describe('2 · public rounds from the Merchant pickup', () => {
  it('round 1 → 3 nearest within 5 km; round 2 → next 3 within 10 km; round 3 → the rest within 10 km; never beyond', () => {
    const s = storeWith({ c1: 1, c2: 2, c3: 3, c4: 4, c5: 6, c6: 7, c7: 9, c8: 9.5, far: 12 });
    const id = newOrder(s);
    expect(pending(s, id).map((o) => o.captainId)).toEqual(['c1', 'c2', 'c3']);
    expireRound(s, id);
    expect(pending(s, id).map((o) => [o.captainId, o.attempt])).toEqual([['c4', 2], ['c5', 2], ['c6', 2]]);
    expireRound(s, id);
    expect(pending(s, id).map((o) => [o.captainId, o.attempt])).toEqual([['c7', 3], ['c8', 3]]);
    expireRound(s, id);
    const order = s.state().orders.find((o) => o.id === id)!;
    expect(order.status).toBe('dispatch_expired');
    const offered = s.state().offers.filter((o) => o.orderId === id).map((o) => o.captainId);
    expect(offered).not.toContain('far');
    expect(new Set(offered).size).toBe(offered.length);
  });

  it('a round with nobody new in range is skipped, not waited out', () => {
    const s = storeWith({ c5: 6, c6: 8 });
    const id = newOrder(s);
    expect(pending(s, id).map((o) => [o.captainId, o.attempt])).toEqual([['c5', 2], ['c6', 2]]);
    expect(s.state().orders.find((o) => o.id === id)!.history.some((h) => h.note?.includes('الجولة 1 من 3: لا يوجد مستلم جديد'))).toBe(true);
  });

  it('only Captains beyond 10 km → straight to the Admin queue with the range reason', () => {
    const s = storeWith({ far: 12 });
    const id = newOrder(s);
    const order = s.state().orders.find((o) => o.id === id)!;
    expect(order).toMatchObject({ status: 'dispatch_expired', queueReason: OUT_OF_RANGE_REASON, dispatchAttempt: MAX_DISPATCH_ROUNDS });
    expect(s.state().offers.some((o) => o.orderId === id)).toBe(false);
  });

  it('the first acceptance ends the rounds; broadcast OFF withdraws open public offers and starts none', () => {
    const s = storeWith({ c1: 1, c2: 2, c3: 3, c4: 4 });
    const a = newOrder(s);
    const [first, second] = pending(s, a);
    valueOf(s.state().acceptOffer(first.id, first.captainId));
    expect(failureOf(s.state().acceptOffer(second.id, second.captainId))).toBe('لم يعد هذا العرض متاحاً');
    const b = newOrder(s);
    valueOf(s.state().setPublicBroadcast(false));
    expect(pending(s, b)).toHaveLength(0);
    s.state().tick(Date.now() + 5 * 60_000);
    expect(pending(s, b)).toHaveLength(0);
    expect(s.state().orders.find((o) => o.id === b)!.status).toBe('pending_dispatch');
  });
});

describe('1 · commission: hold on acceptance, one debit on delivery, revenue from debits only', () => {
  function delivered(rateChangeTo?: number) {
    const s = storeWith({ c1: 1 });
    const id = newOrder(s);
    const offer = pending(s, id)[0];
    valueOf(s.state().acceptOffer(offer.id, 'c1'));
    const accepted = s.state().orders.find((o) => o.id === id)!;
    if (rateChangeTo !== undefined) valueOf(s.state().setCommissionRate(rateChangeTo));
    for (let i = 0; i < 4; i++) s.state().advanceDelivery(id, 'c1');
    return { s, id, accepted };
  }

  it('acceptance locks rate and amount (a hold, not revenue); delivery posts exactly one debit', () => {
    const s = storeWith({ c1: 1 });
    const id = newOrder(s);
    valueOf(s.state().acceptOffer(pending(s, id)[0].id, 'c1'));
    const o = s.state().orders.find((x) => x.id === id)!;
    expect(o.commissionBp).toBe(2000);
    expect(o.commissionFils).toBe(commissionFils(o.deliveryPrice, 2000));
    expect(heldCommission(s.state().orders, 'c1')).toBe(o.commissionFils);
    expect(commissionRevenue(s.state().walletTx, Date.now(), 'all').amount).toBe(0);
    for (let i = 0; i < 4; i++) s.state().advanceDelivery(id, 'c1');
    const debits = s.state().walletTx.filter((t) => t.type === 'commission_debit');
    expect(debits).toHaveLength(1);
    expect(debits[0]).toMatchObject({ captainId: 'c1', orderId: id, amount: -o.commissionFils!, idempotencyKey: `commission:${id}` });
    expect(heldCommission(s.state().orders, 'c1')).toBe(0);
    expect(commissionRevenue(s.state().walletTx, Date.now(), 'today')).toEqual({ amount: o.commissionFils, orders: 1 });
  });

  it('a repeated completion never posts a second debit', () => {
    const { s, id } = delivered();
    expect(failureOf(s.state().advanceDelivery(id, 'c1'))).toBe('تم تأكيد التسليم مسبقاً');
    const data = JSON.parse(JSON.stringify(s.state())) as AppData;
    settleDeliveredCommission(data, data.orders.find((o) => o.id === id)!, Date.now());
    expect(data.walletTx.filter((t) => t.type === 'commission_debit')).toHaveLength(1);
  });

  it('a rate change after acceptance does not touch that order; new acceptances use the new rate', () => {
    const { s, id, accepted } = delivered(1000);
    const debit = s.state().walletTx.find((t) => t.orderId === id)!;
    expect(debit.commissionBp).toBe(2000);
    expect(debit.amount).toBe(-accepted.commissionFils!);
    const next = newOrder(s);
    valueOf(s.state().acceptOffer(pending(s, next)[0].id, 'c1'));
    expect(s.state().orders.find((o) => o.id === next)!.commissionBp).toBe(1000);
  });

  it('cancelling before acceptance creates no hold and no revenue; top-ups are never revenue', () => {
    const s = storeWith({ c1: 1 });
    const id = newOrder(s);
    valueOf(s.state().cancelOrder(id, 'test'));
    valueOf(s.state().rechargeWallet('c1', 5_000, 'op-x'));
    expect(heldCommission(s.state().orders, 'c1')).toBe(0);
    expect(commissionRevenue(s.state().walletTx, Date.now(), 'all').amount).toBe(0);
  });

  it('«مجموع الطلب» never changes the fee or the commission', () => {
    const s = storeWith({ c1: 1 });
    const plainId = newOrder(s);
    const plain = s.state().orders.find((o) => o.id === plainId)!;
    const withTotal = valueOf(s.state().createOrder('m-sanabel', { areaId: 'a-khalda', orderTotal: 99_000 })).id;
    const offer = pending(s, withTotal)[0];
    valueOf(s.state().acceptOffer(offer.id, offer.captainId));
    const o = s.state().orders.find((x) => x.id === withTotal)!;
    expect(o.mealValue).toBe(99_000);
    expect(o.deliveryPrice).toBe(plain.deliveryPrice);
    expect(o.commissionFils).toBe(commissionFils(o.deliveryPrice, 2000));
  });
});

describe('1 · revenue periods follow the Amman calendar', () => {
  const debit = (at: number, amount = -100): WalletTransaction => ({ id: `t${at}`, captainId: 'c', type: 'commission_debit', amount, createdAt: at, actor: { role: 'system', name: 'النظام' } });
  const now = Date.UTC(2026, 10, 25, 9, 0); // 25 Nov, 12:00 Amman (UTC+3)

  it('today, this month and all time', () => {
    const ledger = [
      debit(Date.UTC(2026, 10, 24, 21, 30)), // 25 Nov 00:30 Amman → today
      debit(Date.UTC(2026, 10, 24, 20, 30)), // 24 Nov 23:30 Amman → this month, not today
      debit(Date.UTC(2026, 9, 31, 20, 30)), // 31 Oct 23:30 Amman → earlier month
      { ...debit(Date.UTC(2026, 10, 25, 8, 0), 5_000), type: 'recharge' as const }, // a top-up, never revenue
    ];
    expect(commissionRevenue(ledger, now, 'today')).toEqual({ amount: 100, orders: 1 });
    expect(commissionRevenue(ledger, now, 'month')).toEqual({ amount: 200, orders: 2 });
    expect(commissionRevenue(ledger, now, 'all')).toEqual({ amount: 300, orders: 3 });
  });
});

describe('8 · commission rate setting and password reset', () => {
  it('rate: validated, audited with old/new values, unchanged rate refused', () => {
    const { state } = newStore();
    expect(failureOf(state().setCommissionRate(10_001))).toBe(COMMISSION_RATE_ERROR);
    expect(failureOf(state().setCommissionRate(1.5))).toBe(COMMISSION_RATE_ERROR);
    expect(failureOf(state().setCommissionRate(2000))).toBe('النسبة الجديدة مطابقة للنسبة الحالية');
    valueOf(state().setCommissionRate(1500));
    expect(state().settings.commissionBp).toBe(1500);
    expect(state().adminAudit[0]).toMatchObject({ kind: 'commission_rate', previousBp: 2000, nextBp: 1500, actor: { role: 'admin' } });
  });

  it('reset: new password works, old one stops, the audit never holds a password', () => {
    const { state } = newStore();
    const merchant = state().merchants[0];
    const old = merchant.password;
    expect(valueOf(state().resetAccountPassword({ role: 'merchant', id: merchant.id }, 'Tmp9xKq2Lm'))).toEqual({ name: merchant.businessName, username: merchant.username });
    expect(state().authenticate(merchant.username, 'Tmp9xKq2Lm').ok).toBe(true);
    expect(state().authenticate(merchant.username, old).ok).toBe(false);
    const entry = state().adminAudit[0];
    expect(entry).toMatchObject({ kind: 'password_reset', targetRole: 'merchant', targetId: merchant.id });
    expect(JSON.stringify(state().adminAudit)).not.toContain('Tmp9xKq2Lm');
    expect(JSON.stringify(state().adminAudit)).not.toContain(old);
  });

  it('reset: captains too; unknown accounts and short passwords are refused', () => {
    const { state } = newStore();
    const captain = state().captains[0];
    valueOf(state().resetAccountPassword({ role: 'captain', id: captain.id }, 'Abcdef2345'));
    expect(state().authenticate(captain.username, 'Abcdef2345').ok).toBe(true);
    expect(failureOf(state().resetAccountPassword({ role: 'captain', id: 'nobody' }, 'Abcdef2345'))).toBe('الحساب غير موجود');
    expect(state().resetAccountPassword({ role: 'merchant', id: state().merchants[0].id }, '123').ok).toBe(false);
  });
});

describe('4 · simulated 60-second location reports', () => {
  it('Available idle Captains report; offline, suspended, lost-signal and delivering ones do not', () => {
    const s = storeWith({ idle: 1, off: 2, lost: 3, suspended: 4 });
    const now = Date.now() + 1000;
    s.state().setCaptainAvailability('off', false);
    s.state().setGpsSignal('lost', 'lost');
    s.state().setCaptainStatus('suspended', false);
    s.state().tick(now);
    const src = (id: string) => s.state().captains.find((c) => c.id === id)!.lastLocation!;
    expect(src('idle')).toMatchObject({ source: 'idle_report', recordedAt: now });
    for (const id of ['off', 'lost', 'suspended']) expect(src(id).source).toBe('demo_idle');
    // No new report inside the 60 s window, a new one after it; the position never moves.
    s.state().tick(now + 30_000);
    expect(src('idle').recordedAt).toBe(now);
    s.state().tick(now + 60_000);
    expect(src('idle').recordedAt).toBe(now + 60_000);
    expect(src('idle').position).toEqual(captainAt('idle', 1).lastLocation!.position);
  });

  it('once a Captain goes offline the last report ages out and is no longer current', () => {
    const s = storeWith({ idle: 1 });
    const now = Date.now() + 1000;
    s.state().tick(now);
    s.state().setCaptainAvailability('idle', false);
    s.state().tick(now + 120_000);
    const captain = s.state().captains[0];
    expect(captain.lastLocation!.recordedAt).toBe(now);
    expect(locationFreshness(captain, now + 120_000, 20, undefined)).toBe('last_known');
  });
});

describe('9 · createOrder with «مجموع الطلب»', () => {
  it('stores a valid total, leaves a blank one absent and refuses an invalid one', () => {
    const { state } = newStore();
    const withTotal = valueOf(state().createOrder('m-sanabel', { areaId: 'a-khalda', orderTotal: 12_500 })).id;
    const blank = valueOf(state().createOrder('m-sanabel', { areaId: 'a-khalda' })).id;
    expect(state().orders.find((o) => o.id === withTotal)!.mealValue).toBe(12_500);
    expect(state().orders.find((o) => o.id === blank)!.mealValue).toBeUndefined();
    const bad = state().createOrder('m-sanabel', { areaId: 'a-khalda', orderTotal: -1 });
    expect(bad.ok === false && bad.code).toBe('invalid_total');
    expect(failureOf(state().createOrder('m-sanabel', { areaId: 'a-khalda', orderTotal: 1.5 }))).toBe(ORDER_TOTAL_ERROR);
  });

  it('a pin on the edge of the chosen area is accepted; a pin outside it is refused', () => {
    const { state } = newStore();
    const khalda = state().areas.find((a) => a.id === 'a-khalda')!;
    const edge = { lat: khalda.polygon[0].lat, lng: (khalda.polygon[0].lng + khalda.polygon[1].lng) / 2 };
    expect(state().createOrder('m-sanabel', { areaId: 'a-khalda', location: edge }).ok).toBe(true);
    const outside = state().createOrder('m-sanabel', { areaId: 'a-khalda', location: { lat: 32.5, lng: 36.5 } });
    expect(outside.ok === false && outside.code).toBe('pin_outside_area');
  });
});

describe('saved demo data from before this change is upgraded, not reset', () => {
  it('adds the audit trail and default rate and keeps every record', () => {
    const old = createSeedData() as unknown as Record<string, unknown>;
    delete old.adminAudit;
    old.settings = { publicBroadcast: false };
    const migrated = migrateAppData(old) as AppData;
    expect(migrated.adminAudit).toEqual([]);
    expect(migrated.settings).toEqual({ publicBroadcast: false, commissionBp: 2000 });
    expect(migrated.orders).toBe(old.orders);
    expect(migrated.walletTx).toBe(old.walletTx);
  });

  it('the browser repository loads such data instead of discarding it', () => {
    const old = createSeedData() as unknown as Record<string, unknown>;
    delete old.adminAudit;
    old.settings = { publicBroadcast: true };
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ version: 1, state: old }));
    const loaded = browserRepository.load();
    expect(loaded?.settings.commissionBp).toBe(2000);
    expect(loaded?.orders).toHaveLength((old.orders as unknown[]).length);
    localStorage.clear();
  });
});
