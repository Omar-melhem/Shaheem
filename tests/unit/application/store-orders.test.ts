import { afterEach, describe, expect, it, vi } from 'vitest';
import { AREA_REQUIRED, AREA_UNAVAILABLE } from '@/domain/destination';
import { CUSTOMER_PHONE_ERROR, PHONE_ERROR } from '@/domain/phone';
import { failureOf, newStore, PHONE, valueOf } from './storeHarness';

afterEach(() => vi.useRealTimers());

/** Creates an immediate order for Sanabel → Khalda; returns its id. */
const immediateOrder = (s: ReturnType<typeof newStore>) =>
  valueOf(s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-khalda' })).id;
const order = (s: ReturnType<typeof newStore>, id: string) => s.state().orders.find((o) => o.id === id)!;
const offersOf = (s: ReturnType<typeof newStore>, id: string) => s.state().offers.filter((o) => o.orderId === id);

describe('createOrder validation', () => {
  it('rejects unknown and inactive merchants', () => {
    const s = newStore();
    expect(failureOf(s.state().createOrder('m-nobody', { customerPhone: PHONE, areaId: 'a-khalda' }))).toBe('حساب التاجر غير موجود');
    valueOf(s.state().setMerchantStatus('m-sanabel', false));
    expect(failureOf(s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-khalda' }))).toContain('غير مفعّل');
  });

  it('requires a 10-digit phone and an area', () => {
    const s = newStore();
    expect(failureOf(s.state().createOrder('m-sanabel', { customerPhone: '079', areaId: 'a-khalda' }))).toBe(CUSTOMER_PHONE_ERROR);
    const r = s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: null as never });
    expect(r).toMatchObject({ ok: false, error: AREA_REQUIRED, code: 'no_area' });
  });

  it('an unpriced area is unavailable (never a guessed fee)', () => {
    const s = newStore();
    expect(s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-abdoun' })).toMatchObject({ ok: false, error: AREA_UNAVAILABLE });
  });

  it('rejects an invalid pin and a pin outside the legacy area boundary', () => {
    const s = newStore();
    expect(s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-khalda', location: { lat: 200, lng: 0 } })).toMatchObject({ code: 'invalid_pin' });
    expect(s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-khalda', location: { lat: 31.0, lng: 35.0 } })).toMatchObject({ code: 'pin_outside_area' });
  });

  it('refuses when the fee changed since the merchant saw it, and reports the current fee', () => {
    const s = newStore();
    const fee = s.state().prices.find((p) => p.merchantId === 'm-sanabel' && p.areaId === 'a-khalda')!.price;
    const r = s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-khalda', expectedFee: fee + 1 });
    expect(r).toMatchObject({ ok: false, code: 'fee_changed', currentFee: fee });
  });

  it('scheduled requests need a future pickup time', () => {
    const s = newStore();
    expect(s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-khalda', requestType: 'scheduled' })).toMatchObject({ code: 'no_schedule' });
    expect(s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-khalda', requestType: 'scheduled', scheduledPickupAt: Date.now() - 1 })).toMatchObject({ code: 'schedule_past' });
  });
});

describe('createOrder success', () => {
  it('an immediate order locks the fee, gets the next reference and is broadcast', () => {
    const s = newStore();
    const seq = s.state().seq;
    const { id, reference } = valueOf(s.state().createOrder('m-sanabel', { customerPhone: '٠٧٩١٢٣٤٥٦٧', areaId: 'a-khalda' }));
    const o = order(s, id);
    expect(reference).toBe(`SH-${seq + 1}`);
    expect(o).toMatchObject({ status: 'awaiting_captain', customerPhone: PHONE, areaId: 'a-khalda', requestType: 'immediate', dispatchMode: 'public' });
    expect(o.destination.position).toBeUndefined();
    expect(o.destination.label).toBe('منطقة خلدا');
    expect(offersOf(s, id).filter((x) => x.status === 'pending')).toHaveLength(3); // demo group size
    expect(s.state().alerts[0].kind).toBe('new_order');
  });

  it('a pinned order stores the pin and the place name', () => {
    const s = newStore();
    const { id } = valueOf(s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-khalda', location: { lat: 31.99, lng: 35.83 }, placeName: ' بناية ' }));
    expect(order(s, id).destination).toMatchObject({ position: { lat: 31.99, lng: 35.83 }, label: 'بناية' });
  });

  it('with broadcast off, a new order waits in the Admin queue', () => {
    const s = newStore();
    valueOf(s.state().setPublicBroadcast(false));
    expect(order(s, immediateOrder(s)).status).toBe('pending_dispatch');
  });

  it('a scheduled order is never broadcast and carries its reason', () => {
    const s = newStore();
    const at = Date.now() + 3_600_000;
    const { id } = valueOf(s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-khalda', requestType: 'scheduled', scheduledPickupAt: at }));
    expect(order(s, id)).toMatchObject({ status: 'pending_dispatch', requestType: 'scheduled', scheduledPickupAt: at });
    expect(offersOf(s, id)).toHaveLength(0);
  });
});

describe('broadcast switch, publish, private assignment, cancel', () => {
  it('stopping broadcast withdraws open public offers and returns orders to the queue', () => {
    const s = newStore();
    const id = immediateOrder(s);
    valueOf(s.state().setPublicBroadcast(false));
    expect(order(s, id)).toMatchObject({ status: 'pending_dispatch', queueReason: 'أُوقف البث العام' });
    expect(offersOf(s, id).every((o) => o.status === 'withdrawn')).toBe(true);
  });

  it('dispatchPublic guards broadcast, existence, status and scheduled orders', () => {
    const s = newStore();
    const id = immediateOrder(s);
    expect(failureOf(s.state().dispatchPublic(id))).toContain('لا يمكن نشر طلب');
    valueOf(s.state().setPublicBroadcast(false));
    expect(failureOf(s.state().dispatchPublic(id))).toContain('البث العام متوقف');
    valueOf(s.state().setPublicBroadcast(true));
    expect(failureOf(s.state().dispatchPublic('o-nobody'))).toBe('الطلب غير موجود');
    const sch = valueOf(s.state().createOrder('m-sanabel', { customerPhone: PHONE, areaId: 'a-khalda', requestType: 'scheduled', scheduledPickupAt: Date.now() + 3_600_000 })).id;
    expect(failureOf(s.state().dispatchPublic(sch))).toContain('يُسند يدوياً');
    valueOf(s.state().dispatchPublic(id)); // back in the queue after the switch → can publish again
    expect(order(s, id).status).toBe('awaiting_captain');
  });

  it('assignPrivate offers to one eligible captain only', () => {
    const s = newStore();
    valueOf(s.state().setPublicBroadcast(false));
    const id = immediateOrder(s);
    expect(failureOf(s.state().assignPrivate('o-nobody', 'c-ahmad'))).toBe('الطلب أو الكابتن غير موجود');
    expect(failureOf(s.state().assignPrivate(id, 'c-laith'))).toContain('الكابتن غير مؤهل');
    valueOf(s.state().assignPrivate(id, 'c-ahmad'));
    expect(order(s, id)).toMatchObject({ status: 'offered_privately', dispatchMode: 'private' });
    expect(offersOf(s, id)).toEqual([expect.objectContaining({ captainId: 'c-ahmad', mode: 'private', status: 'pending' })]);
    expect(failureOf(s.state().assignPrivate(id, 'c-mohammad'))).toContain('لا يمكن إسناد طلب');
  });

  it('cancel works only before acceptance and withdraws offers', () => {
    const s = newStore();
    const id = immediateOrder(s);
    expect(failureOf(s.state().cancelOrder('o-nobody', ''))).toBe('الطلب غير موجود');
    valueOf(s.state().cancelOrder(id, '  '));
    expect(order(s, id).status).toBe('cancelled');
    expect(order(s, id).history.slice(-1)[0]?.note).toBe('إلغاء من الإدارة');
    expect(offersOf(s, id).every((o) => o.status !== 'pending')).toBe(true);
    const active = s.state().orders.find((o) => o.status === 'on_the_way')!;
    expect(failureOf(s.state().cancelOrder(active.id, 'x'))).toContain('قبل قبول الكابتن');
  });
});

describe('captain actions', () => {
  it('availability: inactive accounts cannot go online; busy captains cannot go offline', () => {
    const s = newStore();
    expect(failureOf(s.state().setCaptainAvailability('c-nobody', true))).toBe('الكابتن غير موجود');
    expect(failureOf(s.state().setCaptainAvailability('c-laith', true))).toContain('غير مفعّل');
    expect(failureOf(s.state().setCaptainAvailability('c-samer', false))).toContain('أكمل التوصيل الحالي');
    valueOf(s.state().setCaptainAvailability('c-khaled', true));
    expect(s.state().captains.find((c) => c.id === 'c-khaled')?.availability).toBe('available');
  });

  it('going offline withdraws the pending offer; when the round empties the next round starts', () => {
    const s = newStore();
    s.state().updateDemoSettings({ offerPolicy: 'sequential' });
    const id = immediateOrder(s);
    const first = offersOf(s, id)[0];
    valueOf(s.state().setCaptainAvailability(first.captainId, false));
    expect(s.state().offers.find((o) => o.id === first.id)?.status).toBe('withdrawn');
    const pending = offersOf(s, id).filter((o) => o.status === 'pending');
    expect(pending).toHaveLength(1);
    expect(pending[0].captainId).not.toBe(first.captainId);
    expect(pending[0].attempt).toBe(2);
  });

  it('accepting an offer assigns the order, withdraws the others and starts trip tracking', () => {
    const s = newStore();
    const id = immediateOrder(s);
    const [a, b] = offersOf(s, id);
    expect(failureOf(s.state().acceptOffer(a.id, b.captainId))).toBe('العرض غير متاح لهذا الكابتن');
    valueOf(s.state().acceptOffer(a.id, a.captainId));
    expect(order(s, id)).toMatchObject({ status: 'accepted', captainId: a.captainId });
    expect(s.state().offers.find((o) => o.id === b.id)?.status).toBe('withdrawn');
    expect(s.state().captains.find((c) => c.id === a.captainId)?.lastLocation).toMatchObject({ source: 'trip_simulated', activeOrderId: id });
    expect(failureOf(s.state().acceptOffer(b.id, b.captainId))).toBe('لم يعد هذا العرض متاحاً');
  });

  it('an offer cannot be accepted after its window', () => {
    vi.useFakeTimers({ toFake: ['Date'] });
    const s = newStore();
    const id = immediateOrder(s);
    const offer = offersOf(s, id)[0];
    vi.setSystemTime(offer.expiresAt + 1);
    expect(failureOf(s.state().acceptOffer(offer.id, offer.captainId))).toBe('انتهت مهلة العرض');
  });

  it('rejecting a public offer notes it in the history', () => {
    const s = newStore();
    const id = immediateOrder(s);
    const offer = offersOf(s, id)[0];
    expect(failureOf(s.state().rejectOffer(offer.id, 'c-nobody'))).toBe('العرض غير متاح لهذا الكابتن');
    valueOf(s.state().rejectOffer(offer.id, offer.captainId));
    expect(order(s, id).history.slice(-1)[0]?.note).toBe('رفض الكابتن العرض');
    expect(failureOf(s.state().rejectOffer(offer.id, offer.captainId))).toBe('لم يعد هذا العرض متاحاً');
  });

  it('a rejected private offer returns the order to the Admin queue', () => {
    const s = newStore();
    valueOf(s.state().setPublicBroadcast(false));
    const id = immediateOrder(s);
    valueOf(s.state().assignPrivate(id, 'c-ahmad'));
    valueOf(s.state().rejectOffer(offersOf(s, id)[0].id, 'c-ahmad'));
    expect(order(s, id)).toMatchObject({ status: 'pending_dispatch', queueReason: 'رفض الكابتن العرض الخاص' });
  });

  it('only the assigned captain advances the delivery, one stage at a time, to delivered', () => {
    const s = newStore();
    const id = immediateOrder(s);
    const offer = offersOf(s, id)[0];
    valueOf(s.state().acceptOffer(offer.id, offer.captainId));
    expect(failureOf(s.state().advanceDelivery('o-nobody', offer.captainId))).toBe('الطلب غير موجود');
    const other = s.state().captains.find((c) => c.id !== offer.captainId && c.status === 'active')!;
    expect(failureOf(s.state().advanceDelivery(id, other.id))).toBe('هذا الطلب غير مسند إليك');
    const stages = [1, 2, 3, 4].map(() => valueOf(s.state().advanceDelivery(id, offer.captainId)));
    expect(stages).toEqual(['heading_to_pickup', 'picked_up', 'on_the_way', 'delivered']);
    expect(order(s, id).deliveredAt).toBeTypeOf('number');
    expect(s.state().captains.find((c) => c.id === offer.captainId)?.lastLocation?.activeOrderId).toBeUndefined();
    expect(failureOf(s.state().advanceDelivery(id, offer.captainId))).toBe('تم تأكيد التسليم مسبقاً');
  });
});

describe('tick (offer expiry and simulated trip GPS)', () => {
  it('expired offers end the round and start the next one', () => {
    const s = newStore();
    const id = immediateOrder(s);
    const first = offersOf(s, id);
    s.state().tick(first[0].expiresAt + 1);
    expect(first.every((o) => s.state().offers.find((x) => x.id === o.id)?.status === 'expired')).toBe(true);
    expect(offersOf(s, id).filter((o) => o.status === 'pending').every((o) => o.attempt === 2)).toBe(true);
  });

  it('a captain on the way moves towards the customer', () => {
    const s = newStore();
    const active = s.state().orders.find((o) => o.status === 'on_the_way')!;
    const before = s.state().captains.find((c) => c.id === active.captainId)!.lastLocation!;
    s.state().tick(before.recordedAt + 3_000);
    const after = s.state().captains.find((c) => c.id === active.captainId)!.lastLocation!;
    expect(after).toMatchObject({ source: 'trip_simulated', activeOrderId: active.id });
    expect(after.position).not.toEqual(before.position);
  });

  it('lost GPS raises one stale alert, not one per tick', () => {
    const s = newStore();
    const active = s.state().orders.find((o) => o.status === 'on_the_way')!;
    s.state().setGpsSignal(active.captainId!, 'lost');
    const at = s.state().captains.find((c) => c.id === active.captainId)!.lastLocation!.recordedAt;
    const late = at + (s.state().demo.staleAfterSec + 1) * 1000;
    s.state().tick(late);
    s.state().tick(late + 1_000);
    expect(s.state().alerts.filter((a) => a.kind === 'gps_stale' && a.orderId === active.id)).toHaveLength(1);
  });
});

describe('support contacts', () => {
  const phone = { channel: 'phone' as const, label: 'الدعم', value: '٠٧٩١٢٣٤٥٦٧', enabled: true };

  it('validates label, value and phone', () => {
    const s = newStore();
    expect(failureOf(s.state().saveSupportContact({ ...phone, label: ' ' }))).toBe('العنوان وبيانات التواصل مطلوبة');
    expect(failureOf(s.state().saveSupportContact({ ...phone, value: '12' }))).toBe(PHONE_ERROR);
    expect(failureOf(s.state().saveSupportContact({ ...phone, id: 'sc-nobody' }))).toBe('جهة التواصل غير موجودة');
  });

  it('adds in order with a normalised phone, edits, reorders and removes', () => {
    const s = newStore();
    valueOf(s.state().saveSupportContact(phone));
    valueOf(s.state().saveSupportContact({ channel: 'email' as never, label: ' بريد ', value: ' a@b.c ', enabled: true }));
    const [a, b] = [...s.state().supportContacts].sort((x, y) => x.order - y.order);
    expect(a).toMatchObject({ value: PHONE, order: 1 });
    expect(b).toMatchObject({ label: 'بريد', value: 'a@b.c', order: 2 });

    valueOf(s.state().saveSupportContact({ ...a, label: 'الدعم الفني' }));
    expect(s.state().supportContacts.find((c) => c.id === a.id)?.label).toBe('الدعم الفني');

    s.state().moveSupportContact(b.id, -1);
    expect(s.state().supportContacts.find((c) => c.id === b.id)?.order).toBe(1);
    s.state().moveSupportContact(b.id, -1); // already first: no change
    expect(s.state().supportContacts.find((c) => c.id === b.id)?.order).toBe(1);

    s.state().removeSupportContact(a.id);
    expect(s.state().supportContacts.map((c) => c.id)).toEqual([b.id]);
  });
});
