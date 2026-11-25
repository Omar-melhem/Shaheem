import { useMemo } from 'react';
import { AlertTriangle } from 'lucide-react';
import { useAppStore } from '@/app/state';
import { duplicateUsernames } from '@/application/accountIdentity';

/**
 * Reports usernames already shared by several accounts in saved data (from before the global
 * uniqueness rule). Report only: nothing is deleted, merged or renamed; Admin edits one account.
 * Renders nothing when there are none.
 */
export function DuplicateUsernamesNotice() {
  const merchants = useAppStore((s) => s.merchants);
  const captains = useAppStore((s) => s.captains);
  const duplicates = useMemo(() => duplicateUsernames({ merchants, captains }), [merchants, captains]);
  if (duplicates.length === 0) return null;
  return (
    <p className="mb-4 flex items-start gap-2 rounded-xl border border-amber-300 bg-amber-50 px-4 py-3 text-sm text-amber-900" role="status">
      <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" aria-hidden />
      <span>
        أسماء مستخدمين مكررة بين أكثر من حساب: <b dir="ltr">{duplicates.join('، ')}</b>. عدّل اسم المستخدم لأحد الحسابين حتى يصبح الدخول واضحاً.
      </span>
    </p>
  );
}
