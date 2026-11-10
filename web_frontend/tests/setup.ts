// In-memory browser globals so the persisted store can load under Node.
// Imported first by every test file, before the store.
const mem = new Map<string, string>();
const g = globalThis as Record<string, unknown>;
g.localStorage = {
  getItem: (k: string) => mem.get(k) ?? null,
  setItem: (k: string, v: string) => void mem.set(k, v),
  removeItem: (k: string) => void mem.delete(k),
};
g.window = { addEventListener() {}, removeEventListener() {} };
