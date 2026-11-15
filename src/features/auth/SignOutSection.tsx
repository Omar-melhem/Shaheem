import type { ReactNode } from 'react';
import { LogOut } from 'lucide-react';
import { Button, SettingsSection } from '@/shared/components/ui';
import { useConfirmedSignOut } from './hooks/useConfirmedSignOut';

/**
 * The sign-out block at the end of Admin and Merchant Settings — the only web sign-out entry
 * point. It opens the shared confirmation («تأكيد تسجيل الخروج») before the existing sign-out flow.
 */
export function SignOutSection({ icon }: { icon?: ReactNode }) {
  const { requestSignOut, signOutDialog } = useConfirmedSignOut();
  return (
    <SettingsSection title="تسجيل الخروج" icon={icon}>
      <div className="flex flex-col gap-3 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm text-ink-muted">ينهي الجلسة في هذه النافذة فقط، وتعود إلى صفحة الدخول.</p>
        <Button variant="danger" icon={<LogOut className="h-4 w-4" />} onClick={requestSignOut} className="min-h-11 w-full sm:w-auto">
          تسجيل الخروج
        </Button>
      </div>
      {signOutDialog}
    </SettingsSection>
  );
}
