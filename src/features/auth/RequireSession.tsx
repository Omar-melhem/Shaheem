import type { ReactNode } from 'react';
import { Navigate } from 'react-router-dom';
import { useSession, homePathFor } from '@/app/session';
import { useAppStore } from '@/app/state';
import type { Session } from '@/app/state';

/** The tab's session, or null if it points at an account that no longer exists (e.g. after a demo reset). */
export function useValidSession(): Session | null {
  const session = useSession((s) => s.session);
  const exists = useAppStore((s) =>
    !session ? false : session.role === 'admin' ? true : session.role === 'merchant' ? s.merchants.some((m) => m.id === session.id) : s.captains.some((c) => c.id === session.id),
  );
  return exists ? session : null;
}

/**
 * Route guard for the demo session. Merchants and Captains only reach their own
 * screens (data isolation is enforced server-side in production — SRS §5.8).
 */
export function RequireSession({ role, children }: { role: Session['role']; children: ReactNode }) {
  const session = useValidSession();
  if (!session) return <Navigate to="/login" replace />;
  if (session.role !== role) return <Navigate to={homePathFor(session)} replace />;
  return <>{children}</>;
}

export function HomeRedirect() {
  const session = useValidSession();
  return <Navigate to={session ? homePathFor(session) : '/login'} replace />;
}
