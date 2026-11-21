import { describe, expect, it } from 'vitest';
import { eligibleCaptains } from '@/application/captainQueries';
import { merchantOrderOverview, operationalKpis } from '@/application/dashboard';
import { dispatchQueues } from '@/application/dispatchQueues';
import { ALL_OFFERED_REASON, DISPATCH_ROUND_SEC, NO_CANDIDATE_REASON, describeQueueReason } from '@/domain/dispatch';
import { LATE_DELIVERY_AFTER_MIN, ORDER_GROUP_LABEL, countByGroup, isDeliveryLate, orderStatusGroup } from '@/domain/orderStatus';
import type { DeliveryOrder, OrderStatus } from '@/domain/types';
import { createSeedData } from '@/infrastructure/seed';
import { newStore, PHONE, valueOf } from './storeHarness';

const ROUND_MS = (DISPATCH_ROUND_SEC + 1) * 1000;

/** Lets every automatic round expire; returns the order once it is back with Admin. */
function runAllRounds(s: ReturnType<typeof newStore>, id: string) {
  let clock = Date.now();
  for (let i = 0; i < 5; i++) s.state().tick((clock += ROUND_MS));
  return s.state().orders.find((o) => o.id === id)!;
}

describe('captain eligibility: one source for rounds, the assign dialog and the reason (issue 1)', () => {
  it('eligible captains who were all offered already are not reported as «no eligible captain»', () => {
    const s = newStore();
    const eligibleBefore = eligibleCaptains(s.state()).length;
    expect(eligibleBefore).toBeGreaterThan(0);
    const id = valueOf(s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-khalda' })).id;
    const order = runAllRounds(s, id);
    expect(order.status).toBe('dispatch_expired');
    const offered = new Set(s.state().offers.filter((o) => o.orderId === id).map((o) => o.captainId));
    expect(offered.size).toBe(eligibleBefore); // every eligible captain got the offer
    expect(order.queueReason).toBe(ALL_OFFERED_REASON);
    expect(order.queueReason).not.toBe(NO_CANDIDATE_REASON);
  });

  it('«لا يوجد كابتن مؤهل متبقٍ» only when the shared check finds zero eligible captains', () => {
    const s = newStore();
    for (const c of eligibleCaptains(s.state())) valueOf(s.state().setCaptainAvailability(c.id, false));
    expect(eligibleCaptains(s.state())).toHaveLength(0);
    const id = valueOf(s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-khalda' })).id;
    const order = s.state().orders.find((o) => o.id === id)!;
    expect(order.queueReason).toBe(NO_CANDIDATE_REASON);
    expect(describeQueueReason(order.queueReason, 0)).toBe(NO_CANDIDATE_REASON);

    // A captain comes back later: the stored snapshot no longer contradicts the assign dialog.
    valueOf(s.state().setCaptainAvailability('c-ahmad', true));
    const now = eligibleCaptains(s.state()).length;
    expect(now).toBe(1);
    expect(describeQueueReason(order.queueReason, now)).not.toBe(NO_CANDIDATE_REASON);
    expect(describeQueueReason(order.queueReason, now)).toContain('يتوفر الآن 1');
  });

  it('other reasons are shown unchanged', () => {
    expect(describeQueueReason(ALL_OFFERED_REASON, 3)).toBe(ALL_OFFERED_REASON);
    expect(describeQueueReason(undefined, 3)).toBeUndefined();
  });
});

const o = (id: string, status: OrderStatus, over: Partial<DeliveryOrder> = {}) =>
  ({ id, status, requestType: 'immediate', createdAt: 0, updatedAt: 0, ...over }) as DeliveryOrder;

describe('one status grouping and one counter everywhere (issue 2)', () => {
  const orders = [
    o('p', 'pending_dispatch'),
    o('x', 'dispatch_expired'),
    o('pub', 'awaiting_captain'),
    o('priv', 'offered_privately'),
    o('acc', 'accepted', { captainId: 'c' }),
    o('way', 'on_the_way', { captainId: 'c' }),
    o('done', 'delivered', { captainId: 'c', deliveredAt: 0 }),
    o('can', 'cancelled'),
    o('sch', 'pending_dispatch', { requestType: 'scheduled', scheduledPickupAt: 1 }),
    o('schp', 'offered_privately', { requestType: 'scheduled', scheduledPickupAt: 2 }),
  ];

  it('every order falls in exactly one group; failed dispatch is «needs admin», never «pending»', () => {
    const c = countByGroup(orders);
    expect(c).toEqual({ pending_dispatch: 1, needs_admin: 1, offered: 2, active: 2, delivered: 1, cancelled: 1, scheduled_pending: 2 });
    expect(Object.values(c).reduce((a, b) => a + b, 0)).toBe(orders.length);
    expect(orderStatusGroup(o('x', 'dispatch_expired'))).toBe('needs_admin');
    expect(ORDER_GROUP_LABEL.pending_dispatch).toBe('بانتظار التوزيع');
    expect(ORDER_GROUP_LABEL.needs_admin).toBe('بحاجة لتدخل الإدارة');
  });

  it('dashboard KPIs and distribution-center lists give the same count for the same group', () => {
    const k = operationalKpis(orders, 0);
    const q = dispatchQueues(orders);
    expect([k.pendingDispatch, k.needsAdmin, k.offered]).toEqual([q.waiting.length, q.intervention.length, q.offering.length]);
    expect(k.pendingDispatch).toBe(1);
    expect(q.scheduled).toHaveLength(2);
  });

  it('holds on the real seed too', () => {
    const seed = createSeedData();
    const k = operationalKpis(seed.orders, Date.now());
    const q = dispatchQueues(seed.orders);
    const c = countByGroup(seed.orders);
    expect([k.pendingDispatch, k.needsAdmin, k.offered, k.activeDeliveries]).toEqual([c.pending_dispatch, c.needs_admin, c.offered, c.active]);
    expect([q.waiting.length, q.intervention.length, q.offering.length, q.scheduled.length]).toEqual([c.pending_dispatch, c.needs_admin, c.offered, c.scheduled_pending]);
  });
});

describe('merchant active deliveries need a captain (issue 3)', () => {
  it('unassigned and failed orders go to «waiting», not «active»', () => {
    const mine = { merchantId: 'm' };
    const list = [
      o('x', 'dispatch_expired', mine),
      o('p', 'pending_dispatch', mine),
      o('pub', 'awaiting_captain', mine),
      o('way', 'on_the_way', { ...mine, captainId: 'c' }),
      o('done', 'delivered', { ...mine, captainId: 'c' }),
    ];
    const ov = merchantOrderOverview(list, 'm');
    expect(ov.active.map((x) => x.id)).toEqual(['way']);
    expect(ov.active.every((x) => !!x.captainId)).toBe(true);
    expect(ov.waiting.map((x) => x.id).sort()).toEqual(['p', 'pub', 'x']);
    expect(ov.history.map((x) => x.id)).toEqual(['done']);
  });
});

describe('stuck active deliveries are flagged (issue 4)', () => {
  it('an active delivery with no status change past the threshold is late; finished ones never are', () => {
    const now = 10 * 60 * 60_000;
    const limit = LATE_DELIVERY_AFTER_MIN * 60_000;
    expect(isDeliveryLate(o('a', 'on_the_way', { updatedAt: now - limit - 1 }), now)).toBe(true);
    expect(isDeliveryLate(o('a', 'on_the_way', { updatedAt: now - limit + 1000 }), now)).toBe(false);
    expect(isDeliveryLate(o('a', 'delivered', { updatedAt: 0 }), now)).toBe(false);
  });

  it('the fresh seed has no late active delivery', () => {
    const now = Date.now();
    expect(createSeedData(now).orders.filter((x) => isDeliveryLate(x, now))).toHaveLength(0);
  });
});

describe('seed data is realistic (issues 5 and 6)', () => {
  const seed = createSeedData();

  it('order references are consecutive and increase with creation time', () => {
    const refs = seed.orders.map((x) => Number(x.reference.slice(3)));
    expect(refs).toEqual(refs.map((_, i) => 10001 + i));
    for (let i = 1; i < seed.orders.length; i++) expect(seed.orders[i].createdAt).toBeGreaterThanOrEqual(seed.orders[i - 1].createdAt);
    expect(seed.seq).toBe(10000 + seed.orders.length);
  });

  it('no captain has a rating without a completed delivery', () => {
    for (const c of seed.captains.filter((x) => x.rating)) {
      expect(seed.orders.some((x) => x.captainId === c.id && x.status === 'delivered'), c.fullName).toBe(true);
    }
  });

  it('seed alerts point at the expired order and the newest order', () => {
    const expired = seed.orders.find((x) => x.status === 'dispatch_expired')!;
    expect(seed.alerts[0].orderId).toBe(expired.id);
    expect(seed.alerts[1].orderId).toBe(seed.orders[seed.orders.length - 1].id);
  });
});
