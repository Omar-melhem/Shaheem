// @vitest-environment jsdom
import { describe, expect, it } from 'vitest';
import { createApplicationStore } from '@/application/store';
import { browserRepository, STORAGE_KEY } from '@/infrastructure/browserState';
import { createEmptyData } from '@/infrastructure/seed';
import { memoryRepository, valueOf } from '../application/storeHarness';

describe('the live site starts with no fictional data (owner 2026-11-25)', () => {
  it('no merchants, captains, areas, prices, orders, wallet entries or alerts', () => {
    const d = createEmptyData();
    for (const key of ['merchants', 'captains', 'areas', 'routes', 'prices', 'coverage', 'orders', 'offers', 'walletTx', 'alerts', 'supportContacts', 'adminAudit'] as const) {
      expect(d[key], key).toEqual([]);
    }
    expect(d.settings).toEqual({ publicBroadcast: true, commissionBp: 2000 });
  });

  it('old saved demo data is removed, never loaded', () => {
    localStorage.setItem('shahm-demo-v9', JSON.stringify({ version: 1, state: { merchants: [{ id: 'm-old' }] } }));
    localStorage.setItem('shahm-demo-v8', 'x');
    localStorage.setItem('shahm-demo-tick-leader', 'keep');
    expect(browserRepository.load()).toBeNull();
    expect(localStorage.getItem('shahm-demo-v9')).toBeNull();
    expect(localStorage.getItem('shahm-demo-v8')).toBeNull();
    expect(localStorage.getItem('shahm-demo-tick-leader')).toBe('keep');
    expect(STORAGE_KEY).toBe('shahm-demo-v10');
    localStorage.clear();
  });

  it('Admin can build everything from empty: area → merchant → coverage + price → captain → order', () => {
    const store = createApplicationStore(createEmptyData, memoryRepository());
    const s = () => store.getState();
    const areaId = valueOf(s().createZone({ governorateId: 'amman', cityId: 'amman', name: 'خلدا', aliases: [] }));
    const merchantId = valueOf(s().createMerchant({ businessName: 'متجر', category: 'restaurant', phone: '0791112233', cityId: 'amman', areaId, pickup: { lat: 31.99, lng: 35.83 }, username: 'shop1', password: 'x' }));
    valueOf(s().setMerchantCoverage(merchantId, [areaId], true));
    valueOf(s().setMerchantAreaPrice(merchantId, areaId, 1_500));
    valueOf(s().createCaptain({ fullName: 'كابتن', phone: '0795556677', username: 'cap1', password: 'y' }));
    const { reference } = valueOf(s().createOrder(merchantId, { areaId }));
    expect(reference).toBe('SH-10001');
    expect(s().authenticate('shop1', 'x').ok && s().authenticate('cap1', 'y').ok).toBe(true);
  });
});
