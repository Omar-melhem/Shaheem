import { useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAppStore, type Result, type Session } from '@/application/store';
import { useSession, homePathFor } from '@/application/session';

/**
 * Credential check + session start + role redirect, kept out of the form UI.
 * Demo only: credentials are checked against the local prototype store; production
 * replaces this with the real identity provider (SRS §13.3).
 */
export function useDemoSignIn() {
  const authenticate = useAppStore((s) => s.authenticate);
  const signIn = useSession((s) => s.signIn);
  const navigate = useNavigate();
  return useCallback(
    (username: string, password: string): Result<Session> => {
      const result = authenticate(username, password);
      if (result.ok) {
        signIn(result.value);
        navigate(homePathFor(result.value), { replace: true });
      }
      return result;
    },
    [authenticate, signIn, navigate],
  );
}
