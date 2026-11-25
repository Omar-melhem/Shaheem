// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { browserRepository, isAppDataShape, STORAGE_KEY } from '@/infrastructure/browserState';
import { searchPlaces } from '@/infrastructure/placeSearch';
import { createSeedData } from '@/infrastructure/seed';
import { memoryRepository, newStore } from '../application/storeHarness';

beforeEach(() => localStorage.clear());
afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

describe('saved state is checked before use (S5)', () => {
  it('accepts real demo data', () => {
    expect(isAppDataShape(createSeedData())).toBe(true);
  });

  it.each([
    ['null', null],
    ['a string', 'x'],
    ['missing orders', (() => { const d = createSeedData() as unknown as Record<string, unknown>; delete d.orders; return d; })()],
    ['orders not an array', { ...createSeedData(), orders: {} }],
    ['seq not a number', { ...createSeedData(), seq: '10' }],
    ['no settings', { ...createSeedData(), settings: null }],
  ])('rejects %s', (_label, value) => {
    expect(isAppDataShape(value)).toBe(false);
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ version: 1, state: value }));
    expect(browserRepository.load()).toBeNull(); // the store then starts from fresh demo data
  });
});

describe('the simulation tick survives a failed save (H2)', () => {
  it('does not throw and keeps the last good state', () => {
    const repo = memoryRepository();
    const s = newStore(repo);
    const before = s.state().captains; // the seeded active delivery moves its captain on every tick
    repo.failNextSave = true;
    expect(() => s.state().tick(Date.now() + 10 * 60_000)).not.toThrow();
    expect(s.state().captains).toBe(before);
    expect(() => s.state().tick(Date.now() + 11 * 60_000)).not.toThrow();
    expect(s.state().captains).not.toBe(before); // the next tick saves normally again
  });
});

describe('place search hardening (H3)', () => {
  const ok = (body: unknown) => ({ ok: true, json: async () => body }) as Response;

  it('drops results with missing or impossible coordinates', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => ok({
      features: [
        { geometry: { coordinates: [35.87, 31.98] }, properties: { name: 'صحيح' } },
        { geometry: { coordinates: ['x', 31.98] }, properties: { name: 'نص' } },
        { geometry: { coordinates: [35.87, 999] }, properties: { name: 'خارج المدى' } },
        { geometry: {}, properties: { name: 'بلا إحداثيات' } },
        { properties: { name: 'بلا هندسة' } },
      ],
    })));
    const results = await searchPlaces('test');
    expect(results.map((r) => r.name)).toEqual(['صحيح']);
  });

  it('gives up after the timeout with an error the UI shows', async () => {
    vi.useFakeTimers();
    vi.stubGlobal('fetch', vi.fn((_url: string, init: RequestInit) => new Promise((_, reject) => {
      init.signal!.addEventListener('abort', () => reject(Object.assign(new Error('aborted'), { name: 'AbortError' })));
    })));
    const pending = searchPlaces('slow');
    const assertion = expect(pending).rejects.toThrow('timed out');
    await vi.advanceTimersByTimeAsync(8000);
    await assertion;
  });

  it('customer search stays inside Amman; merchant registration search is unbounded', async () => {
    const fetchMock = vi.fn(async () => ok({ features: [] }));
    vi.stubGlobal('fetch', fetchMock);
    await searchPlaces('مطعم');
    await searchPlaces('مطعم', undefined, { bounded: false });
    const urls = (fetchMock.mock.calls as unknown as [string][]).map((c) => c[0]);
    expect(urls[0]).toContain('bbox=');
    expect(urls[1]).not.toContain('bbox=');
  });

  it('a caller abort still reads as an AbortError (not a timeout)', async () => {
    vi.stubGlobal('fetch', vi.fn((_url: string, init: RequestInit) => new Promise((_, reject) => {
      init.signal!.addEventListener('abort', () => reject(Object.assign(new Error('aborted'), { name: 'AbortError' })));
    })));
    const controller = new AbortController();
    const pending = searchPlaces('x', controller.signal);
    controller.abort();
    await expect(pending).rejects.toMatchObject({ name: 'AbortError' });
  });
});
