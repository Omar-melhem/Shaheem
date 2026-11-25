import { describe, expect, it } from 'vitest';
import { PHONE_ERROR } from '@/domain/phone';
import { PICKUP_REQUIRED } from '@/application/merchantLocation';
import { captainInput, failureOf, memoryRepository, merchantInput, newStore, valueOf } from './storeHarness';
import { TOPUP_AMOUNT_ERROR, TOPUP_LIMIT_ERROR } from '@/domain/wallet';

describe('createMerchant', () => {
  it.each([
    [{ businessName: '  ' }, 'اسم النشاط التجاري مطلوب'],
    [{ category: null }, 'اختر فئة النشاط التجاري'],
    [{ phone: '123' }, PHONE_ERROR],
    [{ cityId: null }, 'اختر المدينة'],
    [{ areaId: 'a-khalda', cityId: 'irbid' }, 'اختر منطقة تابعة للمدينة المختارة'],
    [{ pickup: { lat: 0, lng: 0 } }, PICKUP_REQUIRED],
    [{ username: 'ab' }, 'اسم المستخدم: 3 أحرف إنجليزية أو أرقام على الأقل'],
    [{ password: '123' }, 'كلمة المرور 6 أحرف على الأقل'],
    [{ username: 'captain1' }, 'اسم المستخدم مستخدم لحساب آخر'],
    [{ username: 'ADMIN' }, 'اسم المستخدم مستخدم لحساب آخر'],
  ])('rejects %j', (over, message) => {
    const { state } = newStore();
    expect(failureOf(state().createMerchant(merchantInput(over) as never))).toBe(message);
  });

  it('creates an active merchant with a normalised phone and a derived address', () => {
    const { state } = newStore();
    const id = valueOf(state().createMerchant(merchantInput({ phone: '٠٧٩ ١١١ ٢٢٣٣' }) as never));
    expect(state().merchants.find((m) => m.id === id)).toMatchObject({ status: 'active', phone: '0791112233', address: 'الجبيهة، عمّان' });
  });
});

describe('updateMerchant / setMerchantStatus', () => {
  it('fails for an unknown merchant', () => {
    const { state } = newStore();
    expect(failureOf(state().updateMerchant('m-nobody', merchantInput() as never))).toBe('التاجر غير موجود');
    expect(failureOf(state().setMerchantStatus('m-nobody', false))).toBe('التاجر غير موجود');
  });

  it('keeps its own username without a "taken" error', () => {
    const { state } = newStore();
    const m = state().merchants.find((x) => x.id === 'm-sanabel')!;
    valueOf(state().updateMerchant(m.id, { ...m, businessName: 'السنابل الجديد' }));
    expect(state().merchants.find((x) => x.id === 'm-sanabel')?.businessName).toBe('السنابل الجديد');
  });

  it('a legacy merchant with an unchanged text address stays valid, but still needs a category', () => {
    const { state } = newStore();
    const legacy = state().merchants.find((x) => x.id === 'm-yasmine')!;
    expect(legacy.areaId).toBeNull();
    expect(failureOf(state().updateMerchant(legacy.id, legacy))).toBe('اختر فئة النشاط التجاري');
    valueOf(state().updateMerchant(legacy.id, { ...legacy, category: 'other' as const, phone: '0790000299' }));
    expect(state().merchants.find((x) => x.id === 'm-yasmine')).toMatchObject({ areaId: null, phone: '0790000299' });
  });

  it('deactivates and reactivates', () => {
    const { state } = newStore();
    valueOf(state().setMerchantStatus('m-hail', false));
    expect(state().merchants.find((m) => m.id === 'm-hail')?.status).toBe('inactive');
    valueOf(state().setMerchantStatus('m-hail', true));
    expect(state().merchants.find((m) => m.id === 'm-hail')?.status).toBe('active');
  });
});

describe('captains', () => {
  it.each([
    [{ fullName: ' ' }, 'اسم الكابتن مطلوب'],
    [{ phone: ' ' }, 'رقم هاتف الكابتن مطلوب'],
    [{ phone: '12' }, PHONE_ERROR],
    [{ username: 'merchant1' }, 'اسم المستخدم مستخدم لحساب آخر'],
  ])('createCaptain rejects %j', (over, message) => {
    const { state } = newStore();
    expect(failureOf(state().createCaptain(captainInput(over)))).toBe(message);
  });

  it('a new captain starts active but offline, with GPS ok and no location', () => {
    const { state } = newStore();
    const id = valueOf(state().createCaptain(captainInput()));
    const captain = state().captains.find((c) => c.id === id);
    expect(captain).toMatchObject({ status: 'active', availability: 'offline', gpsSignal: 'ok' });
    expect(captain?.lastLocation).toBeUndefined();
  });

  it('updateCaptain validates and saves', () => {
    const { state } = newStore();
    expect(failureOf(state().updateCaptain('c-nobody', captainInput()))).toBe('الكابتن غير موجود');
    expect(failureOf(state().updateCaptain('c-ahmad', captainInput({ fullName: '' })))).toBe('الاسم ورقم الهاتف مطلوبان');
    expect(failureOf(state().updateCaptain('c-ahmad', captainInput({ phone: '1' })))).toBe(PHONE_ERROR);
    valueOf(state().updateCaptain('c-ahmad', captainInput({ fullName: 'أحمد', username: 'captain1' })));
    expect(state().captains.find((c) => c.id === 'c-ahmad')?.fullName).toBe('أحمد');
  });

  it('cannot deactivate a captain on an active delivery', () => {
    const { state } = newStore();
    expect(failureOf(state().setCaptainStatus('c-samer', false))).toBe('لا يمكن إيقاف كابتن لديه توصيل نشط');
    expect(failureOf(state().setCaptainStatus('c-nobody', false))).toBe('الكابتن غير موجود');
  });

  it('deactivating a captain takes them offline and withdraws their pending offers', () => {
    const { state } = newStore();
    valueOf(state().createOrder('m-sanabel', { customerPhone: '0791234567', areaId: 'a-khalda' }));
    const offer = state().offers.find((o) => o.status === 'pending')!;
    valueOf(state().setCaptainStatus(offer.captainId, false));
    expect(state().offers.find((o) => o.id === offer.id)?.status).toBe('withdrawn');
    expect(state().captains.find((c) => c.id === offer.captainId)).toMatchObject({ status: 'inactive', availability: 'offline' });
  });

  it('rateCaptain stores the rating and trims notes (blank → none)', () => {
    const { state } = newStore();
    valueOf(state().rateCaptain('c-ahmad', 3, '  ملاحظة  '));
    expect(state().captains.find((c) => c.id === 'c-ahmad')).toMatchObject({ rating: 3, adminNotes: 'ملاحظة' });
    valueOf(state().rateCaptain('c-ahmad', undefined, '   '));
    expect(state().captains.find((c) => c.id === 'c-ahmad')?.adminNotes).toBeUndefined();
    expect(failureOf(state().rateCaptain('c-nobody', 1, ''))).toBe('الكابتن غير موجود');
  });
});

describe('wallet top-up (demo ledger)', () => {
  it('validates captain, operation and amount (0, negative, fractional fils, over 5 JOD)', () => {
    const { state } = newStore();
    expect(failureOf(state().rechargeWallet('c-nobody', 1_000, 'op-1'))).toBe('الكابتن غير موجود');
    expect(failureOf(state().rechargeWallet('c-ahmad', 1_000, ' '))).toBe('تعذّر تسجيل العملية، أعد المحاولة');
    expect(failureOf(state().rechargeWallet('c-ahmad', 0, 'op-2'))).toBe(TOPUP_AMOUNT_ERROR);
    expect(failureOf(state().rechargeWallet('c-ahmad', -500, 'op-3'))).toBe(TOPUP_AMOUNT_ERROR);
    expect(failureOf(state().rechargeWallet('c-ahmad', 1.5, 'op-4'))).toBe(TOPUP_AMOUNT_ERROR);
    expect(failureOf(state().rechargeWallet('c-ahmad', 5_001, 'op-5'))).toBe(TOPUP_LIMIT_ERROR);
  });

  it('exactly 5.000 JOD is accepted and recorded with its key, actor and no typed reason', () => {
    const { state } = newStore();
    expect(valueOf(state().rechargeWallet('c-yazan', 5_000, 'op-a'))).toEqual({ duplicate: false });
    expect(state().walletTx[0]).toMatchObject({ captainId: 'c-yazan', type: 'recharge', amount: 5_000, idempotencyKey: 'recharge:op-a', actor: { role: 'admin' } });
    expect(state().walletTx[0].reason).toBeUndefined();
  });

  it('a retried confirmation never credits twice; a reused id for a different amount is refused', () => {
    const { state } = newStore();
    const before = state().walletTx.length;
    valueOf(state().rechargeWallet('c-yazan', 2_000, 'op-b'));
    expect(valueOf(state().rechargeWallet('c-yazan', 2_000, 'op-b'))).toEqual({ duplicate: true });
    expect(state().walletTx.length).toBe(before + 1);
    expect(failureOf(state().rechargeWallet('c-yazan', 3_000, 'op-b'))).toBe('رقم العملية مستخدم لعملية أخرى');
  });

  it('a failed save leaves no credit behind', () => {
    const repo = memoryRepository();
    const { state } = newStore(repo);
    const before = state().walletTx.length;
    repo.failNextSave = true;
    expect(state().rechargeWallet('c-yazan', 2_000, 'op-c').ok).toBe(false);
    expect(state().walletTx.length).toBe(before);
  });
});
