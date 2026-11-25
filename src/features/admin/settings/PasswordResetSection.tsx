import { useMemo, useState } from 'react';
import { Copy, KeyRound } from 'lucide-react';
import { generateTemporaryPassword, useAppStore, type PasswordResetTarget } from '@/app/state';
import { Badge, Button, ConfirmDialog, Dialog, Field, OpenDecision, SearchField, Select, SettingsSection } from '@/shared/components/ui';
import { toast } from '@/shared/components/toast';
import { formatDateTime } from '@/shared/lib/format';

interface AccountOption extends PasswordResetTarget {
  name: string;
  username: string;
  active: boolean;
}

const ROLE_LABEL = { merchant: 'تاجر', captain: 'كابتن' } as const;
const AUDIT_PREVIEW = 5;

/**
 * «إعادة تعيين كلمة المرور» for a Merchant or Captain (not Admin's own password — a separate use
 * case). Admin picks the account, confirms, and gets a one-time temporary password to hand over.
 * The current password is never shown. DEMO: credentials live in this browser; production needs
 * the server-side reset contract (docs/owner-requirements-2026-11-25.md §8).
 */
export function PasswordResetSection() {
  const merchants = useAppStore((s) => s.merchants);
  const captains = useAppStore((s) => s.captains);
  const audit = useAppStore((s) => s.adminAudit);
  const resetAccountPassword = useAppStore((s) => s.resetAccountPassword);
  const [role, setRole] = useState<PasswordResetTarget['role']>('merchant');
  const [q, setQ] = useState('');
  const [selectedId, setSelectedId] = useState('');
  const [confirming, setConfirming] = useState(false);
  const [handoff, setHandoff] = useState<{ name: string; username: string; password: string } | null>(null);

  const accounts: AccountOption[] = useMemo(
    () =>
      role === 'merchant'
        ? merchants.map((m) => ({ role, id: m.id, name: m.businessName, username: m.username, active: m.status === 'active' }))
        : captains.map((c) => ({ role, id: c.id, name: c.fullName, username: c.username, active: c.status === 'active' })),
    [role, merchants, captains],
  );
  const needle = q.trim().toLowerCase();
  const matches = accounts.filter((a) => !needle || a.name.toLowerCase().includes(needle) || a.username.toLowerCase().includes(needle));
  const selected = accounts.find((a) => a.id === selectedId) ?? null;
  const resets = audit.filter((a) => a.kind === 'password_reset').slice(0, AUDIT_PREVIEW);

  const reset = () => {
    if (!selected) return false;
    const password = generateTemporaryPassword();
    const result = resetAccountPassword({ role: selected.role, id: selected.id }, password);
    if (!result.ok) {
      toast.error(result.error);
      return false;
    }
    setHandoff({ ...result.value, password });
    setSelectedId('');
    return true;
  };

  const copy = async () => {
    if (!handoff) return;
    try {
      await navigator.clipboard.writeText(handoff.password);
      toast.success('تم نسخ كلمة المرور المؤقتة');
    } catch {
      toast.error('تعذّر النسخ — انسخها يدوياً');
    }
  };

  return (
    <SettingsSection title="إعادة تعيين كلمة المرور" description="لحسابات التجار والكباتن. لا تُعرض كلمة المرور الحالية أبداً." icon={<KeyRound className="h-5 w-5" />}>
      <div className="space-y-4 px-5 py-4">
        <div className="grid gap-3 sm:grid-cols-[10rem_minmax(0,1fr)]">
          <Field label="نوع الحساب" htmlFor="reset-role">
            <Select id="reset-role" value={role} onChange={(e) => { setRole(e.target.value as PasswordResetTarget['role']); setSelectedId(''); setQ(''); }}>
              <option value="merchant">تاجر</option>
              <option value="captain">كابتن</option>
            </Select>
          </Field>
          <SearchField label="بحث بالاسم أو اسم المستخدم" placeholder="ابحث بالاسم أو اسم المستخدم" value={q} onChange={(e) => setQ(e.target.value)} />
        </div>
        <Field label="الحساب" htmlFor="reset-account">
          <Select id="reset-account" value={selectedId} onChange={(e) => setSelectedId(e.target.value)}>
            <option value="">{matches.length ? 'اختر الحساب' : 'لا توجد حسابات مطابقة'}</option>
            {matches.map((a) => (
              <option key={a.id} value={a.id}>{a.name} — {a.username}{a.active ? '' : ' (موقوف)'}</option>
            ))}
          </Select>
        </Field>
        <div className="flex flex-wrap items-center gap-3">
          <Button variant="outline" icon={<KeyRound className="h-4 w-4" />} disabled={!selected} onClick={() => setConfirming(true)}>
            إعادة تعيين كلمة المرور
          </Button>
          {selected && !selected.active && <Badge tone="warning">الحساب موقوف — لن يستطيع الدخول حتى يُفعَّل</Badge>}
        </div>

        {resets.length > 0 && (
          <div>
            <p className="mb-1 text-sm font-bold">آخر عمليات إعادة التعيين</p>
            <ul className="space-y-1 text-xs text-ink-soft">
              {resets.map((r) => r.kind === 'password_reset' && (
                <li key={r.id} className="flex flex-wrap gap-x-2">
                  <span className="whitespace-nowrap">{formatDateTime(r.at)}</span>
                  <span>{ROLE_LABEL[r.targetRole]}: {r.targetName}</span>
                  <span className="text-ink-muted">{r.actor.name}</span>
                </li>
              ))}
            </ul>
          </div>
        )}
        <OpenDecision id="أمان">نموذج عرض: الحسابات محفوظة في هذا المتصفح. في الإنتاج تتم إعادة التعيين على الخادم (صلاحيات، تشفير، حد للمحاولات، إنهاء الجلسات، وتسليم آمن) — بانتظار اعتماد طريقة التسليم.</OpenDecision>
      </div>

      <ConfirmDialog
        open={confirming && !!selected}
        onClose={() => setConfirming(false)}
        onConfirm={reset}
        title="إعادة تعيين كلمة المرور؟"
        confirmLabel="إعادة التعيين"
        variant="danger"
      >
        {selected && (
          <div className="mt-3 space-y-2 rounded-xl bg-cream p-4 text-sm">
            <p>{ROLE_LABEL[selected.role]}: <b>{selected.name}</b></p>
            <p>اسم المستخدم: <b dir="ltr">{selected.username}</b></p>
            <p className="text-xs text-ink-muted">ستتوقف كلمة المرور الحالية فوراً، وتظهر لك كلمة مؤقتة مرة واحدة لتسليمها لصاحب الحساب.</p>
          </div>
        )}
      </ConfirmDialog>

      <Dialog
        open={!!handoff}
        onClose={() => setHandoff(null)}
        size="sm"
        title="كلمة المرور المؤقتة"
        description={handoff ? `للحساب «${handoff.name}» (${handoff.username}). تظهر مرة واحدة فقط — سلّمها لصاحب الحساب مباشرة.` : undefined}
        footer={<Button onClick={() => setHandoff(null)}>تم التسليم</Button>}
      >
        {handoff && (
          <div className="flex items-center gap-2 rounded-xl bg-cream p-3">
            <code dir="ltr" className="flex-1 select-all font-mono text-lg font-bold tracking-wider text-ink">{handoff.password}</code>
            <Button variant="outline" size="sm" icon={<Copy className="h-4 w-4" />} onClick={copy}>نسخ</Button>
          </div>
        )}
      </Dialog>
    </SettingsSection>
  );
}
