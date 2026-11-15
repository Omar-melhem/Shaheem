import { describe, expect, it } from 'vitest';
import { DEMO_ADMIN } from '@/application/store';
import { createSeedData } from '@/infrastructure/seed';
import { failureOf, memoryRepository, newStore, valueOf } from './storeHarness';

describe('store persistence (AppRepository port)', () => {
  it('starts from seed data when the repository is empty', () => {
    const { state } = newStore();
    expect(state().merchants.length).toBeGreaterThan(0);
    expect(state().settings.publicBroadcast).toBe(true);
  });

  it('starts from saved data when the repository has some', () => {
    const saved = createSeedData();
    saved.settings.publicBroadcast = false;
    const { state } = newStore(memoryRepository(saved));
    expect(state().settings.publicBroadcast).toBe(false);
  });

  it('saves the complete next state after a successful action', () => {
    const { state, repo } = newStore();
    valueOf(state().setPublicBroadcast(false));
    expect(repo.saves).toBe(1);
    expect(repo.saved?.settings.publicBroadcast).toBe(false);
  });

  it('does not save when an action changes nothing', () => {
    const { state, repo } = newStore();
    valueOf(state().setPublicBroadcast(true)); // already on
    expect(repo.saves).toBe(0);
  });

  it('a failed save returns an Arabic error and leaves memory unchanged', () => {
    const { state, repo } = newStore();
    repo.failNextSave = true;
    expect(failureOf(state().setPublicBroadcast(false))).toBe('تعذّر حفظ البيانات. لم يُطبَّق أي تغيير، حاول مرة أخرى.');
    expect(state().settings.publicBroadcast).toBe(true);
  });

  it('resetDemo restores the seed', () => {
    const { state } = newStore();
    valueOf(state().setPublicBroadcast(false));
    state().resetDemo();
    expect(state().settings.publicBroadcast).toBe(true);
  });
});

describe('authenticate (demo accounts)', () => {
  it('signs in the admin', () => {
    const { state } = newStore();
    expect(valueOf(state().authenticate(DEMO_ADMIN.username, DEMO_ADMIN.password))).toEqual({ role: 'admin', id: 'admin' });
  });

  it('routes merchants and captains by account, ignoring username case and spaces', () => {
    const { state } = newStore();
    expect(valueOf(state().authenticate('  Merchant1 ', 'demo1234'))).toEqual({ role: 'merchant', id: 'm-sanabel' });
    expect(valueOf(state().authenticate('captain1', 'demo1234'))).toEqual({ role: 'captain', id: 'c-ahmad' });
  });

  it('rejects a wrong password with one generic message', () => {
    const { state } = newStore();
    expect(failureOf(state().authenticate('merchant1', 'nope'))).toBe('اسم المستخدم أو كلمة المرور غير صحيحة');
    expect(failureOf(state().authenticate('admin', 'nope'))).toBe('اسم المستخدم أو كلمة المرور غير صحيحة');
  });
});

describe('alerts and demo controls', () => {
  it('markAlertsRead marks every alert as read', () => {
    const { state } = newStore();
    valueOf(state().setPublicBroadcast(false)); // creates an alert
    state().markAlertsRead();
    expect(state().alerts.every((a) => a.read)).toBe(true);
  });

  it('updateDemoSettings merges the patch', () => {
    const { state } = newStore();
    state().updateDemoSettings({ groupSize: 5 });
    expect(state().demo.groupSize).toBe(5);
    expect(state().demo.offerTimeoutSec).toBe(60);
  });

  it('setGpsSignal changes one captain and ignores unknown ids', () => {
    const { state } = newStore();
    state().setGpsSignal('c-ahmad', 'lost');
    state().setGpsSignal('c-nobody', 'lost');
    expect(state().captains.find((c) => c.id === 'c-ahmad')?.gpsSignal).toBe('lost');
  });

  it('setCaptainDemoLocation moves an idle captain but never one on a delivery', () => {
    const { state } = newStore();
    const pos = { lat: 31.96, lng: 35.88 };
    valueOf(state().setCaptainDemoLocation('c-ahmad', pos));
    expect(state().captains.find((c) => c.id === 'c-ahmad')?.lastLocation).toMatchObject({ position: pos, source: 'demo_idle' });
    expect(failureOf(state().setCaptainDemoLocation('c-samer', pos))).toContain('أثناء توصيل نشط');
    expect(failureOf(state().setCaptainDemoLocation('c-nobody', pos))).toBe('الكابتن غير موجود');
  });
});
