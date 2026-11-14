import type { AppData } from '@/application/data';
import type { AppRepository } from '@/application/ports/AppRepository';
export const STORAGE_KEY = 'shahm-demo-v8';
export const browserRepository: AppRepository = {
  load() {
    try { const raw = localStorage.getItem(STORAGE_KEY); if (!raw) return null; const saved = JSON.parse(raw); return saved.version === 1 ? saved.state : null; } catch { return null; }
  },
  save(data) { localStorage.setItem(STORAGE_KEY, JSON.stringify({ state: data, version: 1 })); },
};
export function observeStorage(key: string, refresh: () => void) {
  const handler = (e: StorageEvent) => { if (e.key === key) refresh(); };
  window.addEventListener('storage', handler);
  return () => window.removeEventListener('storage', handler);
}
/** Existing single-browser demo lease, outside the application policy. */
export function startSimulationClock(tick: (now: number) => void) {
  const id = Math.random().toString(36).slice(2), key = 'shahm-demo-tick-leader';
  const timer = setInterval(() => {
    const now = Date.now();
    try {
      const raw = localStorage.getItem(key);
      const leader = raw ? JSON.parse(raw) as { id: string; at: number } : null;
      if (leader && leader.id !== id && now - leader.at < 3000) return;
      localStorage.setItem(key, JSON.stringify({ id, at: now }));
    } catch { /* Storage unavailable: retain local demo ticking. */ }
    tick(now);
  }, 1000);
  return () => clearInterval(timer);
}
