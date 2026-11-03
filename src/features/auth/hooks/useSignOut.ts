import { useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useSession } from '@/application/session';

/** Ends the demo session for this tab and returns to the login page. */
export function useSignOut() {
  const signOut = useSession((s) => s.signOut);
  const navigate = useNavigate();
  return useCallback(() => {
    signOut();
    navigate('/login', { replace: true });
  }, [signOut, navigate]);
}
