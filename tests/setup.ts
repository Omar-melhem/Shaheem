// Shared test setup (vitest.config.ts → setupFiles).
import { afterEach } from 'vitest';
import '@testing-library/jest-dom/vitest';

// Node tests: in-memory browser globals so the persisted store can load. jsdom tests keep jsdom's own.
const g = globalThis as Record<string, unknown>;
if (typeof g.localStorage === 'undefined') {
  const mem = new Map<string, string>();
  g.localStorage = {
    getItem: (k: string) => mem.get(k) ?? null,
    setItem: (k: string, v: string) => void mem.set(k, v),
    removeItem: (k: string) => void mem.delete(k),
    clear: () => mem.clear(),
  };
}
if (typeof g.window === 'undefined') g.window = { addEventListener() {}, removeEventListener() {} };

// Unmount React trees between component tests.
if (typeof document !== 'undefined') {
  const { cleanup } = await import('@testing-library/react');
  afterEach(() => cleanup());
}
