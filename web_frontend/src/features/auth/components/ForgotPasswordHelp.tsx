import { useState } from 'react';
import { useAppStore } from '@/application/store';
import { Button, Dialog } from '@/shared/components/ui';
import { SupportContactList } from '@/features/support/SupportContacts';

/**
 * "Forgot password?" help (FU-1.2 §2.3). There is no reset workflow: the dialog tells
 * the user to contact SHAHM Administration and lists official contacts only if Admin
 * has configured them — nothing is invented.
 */
export function ForgotPasswordHelp() {
  const [open, setOpen] = useState(false);
  const hasContacts = useAppStore((s) => s.supportContacts.some((c) => c.enabled));

  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        className="rounded-md py-1 text-sm font-bold text-primary underline-offset-4 hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300"
      >
        نسيت كلمة المرور؟
      </button>
      <Dialog
        open={open}
        onClose={() => setOpen(false)}
        size="sm"
        title="نسيت كلمة المرور؟"
        footer={<Button onClick={() => setOpen(false)}>حسناً</Button>}
      >
        <p className="text-[15px] leading-relaxed text-ink-soft">لإعادة تعيين كلمة المرور، يُرجى التواصل مع إدارة شهم.</p>
        {hasContacts && (
          <div className="mt-4">
            <SupportContactList compact />
          </div>
        )}
      </Dialog>
    </>
  );
}
