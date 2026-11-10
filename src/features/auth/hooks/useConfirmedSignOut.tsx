import { useState } from 'react';
import { ConfirmDialog } from '@/shared/components/ui';
import { useSignOut } from './useSignOut';

/**
 * Every sign-out entry point (Admin, Merchant, Captain) asks first. The dialog only gates the
 * existing `useSignOut` flow (session store sign-out → /login); no session handling lives here.
 * Render `signOutDialog` once in the component that owns the button.
 */
export function useConfirmedSignOut() {
  const signOut = useSignOut();
  const [open, setOpen] = useState(false);
  const signOutDialog = (
    <ConfirmDialog
      open={open}
      onClose={() => setOpen(false)}
      onConfirm={signOut}
      title="تأكيد تسجيل الخروج"
      description="هل أنت متأكد أنك تريد تسجيل الخروج؟"
      cancelLabel="إلغاء"
      confirmLabel="تسجيل الخروج"
      variant="danger"
    />
  );
  return { requestSignOut: () => setOpen(true), signOutDialog };
}
