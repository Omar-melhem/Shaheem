// @vitest-environment jsdom
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { browserRepository, observeStorage, startSimulationClock, STORAGE_KEY } from '@/infrastructure/browserState';
import { homePathFor, useSession } from '@/infrastructure/session';
import { searchPlaces } from '@/infrastructure/placeSearch';
import { createSeedData } from '@/infrastructure/seed';

beforeEach(() => {
  localStorage.clear();
  sessionStorage.clear();
});
afterEach(() => {
  vi.useRealTimers();
  vi.unstubAllGlobals();
});

describe('browserRepository (localStorage adapter)', () => {
  it('returns null when nothing is saved', () => {
    expect(browserRepository.load()).toBeNull();
  });

  it('saves under the existing key and format, and loads it back', () => {
    const data = createSeedData();
    browserRepository.save(data);
    expect(JSON.parse(localStorage.getItem(STORAGE_KEY)!)).toMatchObject({ version: 1, state: { seq: data.seq } });
    expect(browserRepository.load()?.seq).toBe(data.seq);
  });

  it('ignores another version and corrupt JSON instead of crashing', () => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ version: 0, state: {} }));
    expect(browserRepository.load()).toBeNull();
    localStorage.setItem(STORAGE_KEY, '{not json');
    expect(browserRepository.load()).toBeNull();
  });
});

describe('observeStorage (cross-tab sync)', () => {
  it('calls back only for its key, and stops after unsubscribe', () => {
    const refresh = vi.fn();
    const stop = observeStorage(STORAGE_KEY, refresh);
    window.dispatchEvent(new StorageEvent('storage', { key: 'other' }));
    window.dispatchEvent(new StorageEvent('storage', { key: STORAGE_KEY }));
    stop();
    window.dispatchEvent(new StorageEvent('storage', { key: STORAGE_KEY }));
    expect(refresh).toHaveBeenCalledTimes(1);
  });
});

describe('startSimulationClock (one ticking tab)', () => {
  it('ticks every second and takes the leader lease', () => {
    vi.useFakeTimers();
    const tick = vi.fn();
    const stop = startSimulationClock(tick);
    vi.advanceTimersByTime(3_000);
    stop();
    vi.advanceTimersByTime(3_000);
    expect(tick).toHaveBeenCalledTimes(3);
    expect(JSON.parse(localStorage.getItem('shahm-demo-tick-leader')!)).toHaveProperty('id');
  });

  it('stays quiet while another tab holds a fresh lease', () => {
    vi.useFakeTimers();
    const tick = vi.fn();
    const stop = startSimulationClock(tick);
    localStorage.setItem('shahm-demo-tick-leader', JSON.stringify({ id: 'other-tab', at: Date.now() + 10_000 }));
    vi.advanceTimersByTime(2_000);
    stop();
    expect(tick).not.toHaveBeenCalled();
  });
});

describe('session (per-tab demo login)', () => {
  it('signs in and out, persisted in sessionStorage', () => {
    useSession.getState().signIn({ role: 'merchant', id: 'm-sanabel' });
    expect(useSession.getState().session).toEqual({ role: 'merchant', id: 'm-sanabel' });
    expect(sessionStorage.getItem('shahm-session')).toContain('m-sanabel');
    useSession.getState().signOut();
    expect(useSession.getState().session).toBeNull();
  });

  it('routes each role to its home', () => {
    expect(homePathFor({ role: 'admin', id: 'admin' })).toBe('/admin');
    expect(homePathFor({ role: 'merchant', id: 'm' })).toBe('/merchant');
    expect(homePathFor({ role: 'captain', id: 'c' })).toBe('/captain');
  });
});

describe('searchPlaces (Photon adapter)', () => {
  const feature = (properties: Record<string, unknown>, lng = 35.9, lat = 31.95) => ({ geometry: { coordinates: [lng, lat] }, properties });

  it('queries Photon inside the Amman box and maps results to the app model', async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({
        features: [
          feature({ osm_type: 'N', osm_id: 7, name: 'مكة مول', street: 'شارع مكة', district: 'خلدا', city: 'عمّان' }),
          feature({ street: 'شارع الجامعة', housenumber: '12', locality: 'الجبيهة' }),
          feature({}), // no name → dropped
        ],
      }),
    });
    vi.stubGlobal('fetch', fetchMock);
    const results = await searchPlaces('مكة مول');
    const url = String(fetchMock.mock.calls[0][0]);
    expect(url).toContain('photon.komoot.io');
    expect(url).toContain(encodeURIComponent('مكة مول'));
    expect(url).toContain('bbox=35.70,31.80,36.10,32.15');
    expect(results).toEqual([
      { id: 'N7', name: 'مكة مول', context: 'شارع مكة، خلدا، عمّان', position: { lat: 31.95, lng: 35.9 } },
      { id: 'شارع الجامعة 12', name: 'شارع الجامعة 12', context: 'الجبيهة', position: { lat: 31.95, lng: 35.9 } },
    ]);
  });

  it('throws on an HTTP error so the UI can show it', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: false, status: 503 }));
    await expect(searchPlaces('x')).rejects.toThrow('place search failed: 503');
  });

  it('handles a response without features', async () => {
    vi.stubGlobal('fetch', vi.fn().mockResolvedValue({ ok: true, json: async () => ({}) }));
    await expect(searchPlaces('x')).resolves.toEqual([]);
  });
});
