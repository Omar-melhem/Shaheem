import type { AppData } from '@/application/data';
import type { AppRepository } from '@/application/ports/AppRepository';
import { DEFAULT_COMMISSION_BP, isValidCommissionBp } from '@/domain/commission';
export const STORAGE_KEY = 'shahm-demo-v10';
/** Earlier keys hold the old fictional demo data; they are removed, never read (owner, 2026-11-25). */
const LEGACY_KEY = /^shahm-demo-v\d+$/;

function removeLegacyData() {
  for (let i = localStorage.length - 1; i >= 0; i--) {
    const key = localStorage.key(i);
    if (key && key !== STORAGE_KEY && LEGACY_KEY.test(key)) localStorage.removeItem(key);
  }
}

const ARRAY_KEYS = ['merchants', 'captains', 'areas', 'routes', 'prices', 'coverage', 'pricingAudit', 'orders', 'offers', 'walletTx', 'supportContacts', 'alerts', 'adminAudit'] as const;

/**
 * Upgrades saved demo data from before the commission ledger (2026-11-25) in place of discarding
 * it: adds the empty audit trail and the default commission rate. Orders, wallet history and every
 * other record are kept exactly as saved. Anything that is not an object is returned unchanged.
 */
export function migrateAppData(value: unknown): unknown {
  if (!value || typeof value !== 'object') return value;
  const v = value as Record<string, unknown>;
  const settings = v.settings && typeof v.settings === 'object' ? (v.settings as Record<string, unknown>) : null;
  return {
    ...v,
    adminAudit: v.adminAudit === undefined ? [] : v.adminAudit,
    settings: settings && !isValidCommissionBp(settings.commissionBp as number) ? { ...settings, commissionBp: DEFAULT_COMMISSION_BP } : v.settings,
  };
}

/**
 * Minimal shape check for data read back from localStorage (it can be corrupted or edited by hand).
 * Anything that fails falls back to fresh demo data instead of crashing the app.
 */
export function isAppDataShape(value: unknown): value is AppData {
  if (!value || typeof value !== 'object') return false;
  const v = value as Record<string, unknown>;
  return (
    ARRAY_KEYS.every((k) => Array.isArray(v[k])) &&
    !!v.settings && typeof v.settings === 'object' &&
    !!v.demo && typeof v.demo === 'object' &&
    typeof v.seq === 'number' && Number.isFinite(v.seq)
  );
}

export const browserRepository: AppRepository = {
  load() {
    try {
      removeLegacyData();
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return null;
      const saved = JSON.parse(raw) as { version?: unknown; state?: unknown };
      if (saved?.version !== 1) return null;
      const state = migrateAppData(saved.state);
      return isAppDataShape(state) ? state : null;
    } catch {
      return null;
    }
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
