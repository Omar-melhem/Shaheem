// A fresh, isolated application store per test, persisted to an in-memory repository.
import { expect } from 'vitest';
import { createApplicationStore, type Result } from '@/application/store';
import type { AppData } from '@/application/data';
import type { AppRepository } from '@/application/ports/AppRepository';
import { createSeedData } from '@/infrastructure/seed';

export interface MemoryRepository extends AppRepository {
  saves: number;
  saved: AppData | null;
  /** When true, the next save throws (simulates storage full / unavailable). */
  failNextSave: boolean;
}

export function memoryRepository(initial: AppData | null = null): MemoryRepository {
  const repo: MemoryRepository = {
    saves: 0,
    saved: initial,
    failNextSave: false,
    load: () => repo.saved,
    save: (data) => {
      if (repo.failNextSave) {
        repo.failNextSave = false;
        throw new Error('quota exceeded');
      }
      repo.saves++;
      repo.saved = JSON.parse(JSON.stringify(data)) as AppData;
    },
  };
  return repo;
}

export function newStore(repo: MemoryRepository = memoryRepository()) {
  const store = createApplicationStore(() => createSeedData(), repo);
  return { store, repo, state: () => store.getState() };
}

/** Asserts a failed Result and returns its message. */
export function failureOf(result: Result<unknown>): string {
  expect(result.ok, 'expected the action to fail').toBe(false);
  return result.ok ? '' : result.error;
}

/** Asserts a successful Result and returns its value. */
export function valueOf<T>(result: Result<T>): T {
  if (!result.ok) throw new Error(`expected success, got: ${result.error}`);
  return result.value;
}

export const PHONE = '0791234567';

export const merchantInput = (over: Record<string, unknown> = {}) => ({
  businessName: 'متجر جديد',
  category: 'restaurant' as const,
  phone: '0791112233',
  cityId: 'amman',
  areaId: 'a-jubaiha',
  pickup: { lat: 32.02, lng: 35.86 },
  username: 'newshop',
  password: 'secret1',
  ...over,
});

export const captainInput = (over: Record<string, unknown> = {}) => ({
  fullName: 'كابتن جديد',
  phone: '0795556677',
  username: 'newcap',
  password: 'secret1',
  ...over,
});
