import { create } from 'zustand';
import { persist, createJSONStorage } from 'zustand/middleware';
import type { Session } from '@/application/store';

/**
 * Demo login session, kept in sessionStorage so each browser tab can be signed
 * in as a different role (Admin / Merchant / Captain) during a presentation.
 */
interface SessionState {
  session: Session | null;
  signIn: (s: Session) => void;
  signOut: () => void;
}

export const useSession = create<SessionState>()(
  persist(
    (set) => ({
      session: null,
      signIn: (session) => set({ session }),
      signOut: () => set({ session: null }),
    }),
    { name: 'shahm-session', storage: createJSONStorage(() => sessionStorage) },
  ),
);

export const homePathFor = (s: Session) => (s.role === 'admin' ? '/admin' : s.role === 'merchant' ? '/merchant' : '/captain');
