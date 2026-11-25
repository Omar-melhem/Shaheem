import type { ID } from '@/domain/types';
import { canonicalUsername } from '@/domain/account';
import type { AppData } from './data';

/** The fixed demo Admin identity shares the login namespace with Merchants and Captains. */
export const DEMO_ADMIN = { username: 'admin', password: 'admin1234' };

interface LoginIdentity {
  id: ID;
  role: 'admin' | 'merchant' | 'captain';
  username: string;
}

/** Every login identity, active or suspended: suspended accounts keep their username. */
export function loginIdentities(data: Pick<AppData, 'merchants' | 'captains'>): LoginIdentity[] {
  return [
    { id: 'admin', role: 'admin', username: DEMO_ADMIN.username },
    ...data.merchants.map((m) => ({ id: m.id, role: 'merchant' as const, username: m.username })),
    ...data.captains.map((c) => ({ id: c.id, role: 'captain' as const, username: c.username })),
  ];
}

/** True when another identity (any role) already uses this username. `exceptId` = the account being edited. */
export function isUsernameTaken(data: Pick<AppData, 'merchants' | 'captains'>, username: string, exceptId?: ID): boolean {
  const key = canonicalUsername(username);
  return loginIdentities(data).some((i) => i.id !== exceptId && canonicalUsername(i.username) === key);
}

/**
 * Usernames shared by more than one identity in existing data (e.g. saved before the rule was
 * enforced). Reported to Admin only — never deleted, merged or renamed automatically.
 */
export function duplicateUsernames(data: Pick<AppData, 'merchants' | 'captains'>): string[] {
  const counts = new Map<string, number>();
  for (const i of loginIdentities(data)) counts.set(canonicalUsername(i.username), (counts.get(canonicalUsername(i.username)) ?? 0) + 1);
  return [...counts].filter(([, n]) => n > 1).map(([name]) => name).sort();
}
