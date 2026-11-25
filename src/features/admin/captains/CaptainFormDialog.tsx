import { useEffect, useState } from 'react';
import { useAppStore, type CaptainInput } from '@/app/state';
import type { Captain } from '@/domain/types';
import { PHONE_ERROR, isValidPhone } from '@/domain/phone';
import { AccountCredentialsFields, credentialFieldErrors, credentialFieldOf } from '../AccountCredentialsFields';
import { Button, Dialog, Field, Input, PhoneField, PHONE_HINT } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';

const EMPTY: CaptainInput = { fullName: '', phone: '', username: '', password: '' };

/** Add / edit a Captain: name, phone and demo credentials only (no vehicle data). */
export function CaptainFormDialog({ captain, onClose }: { captain: Captain | 'new' | null; onClose: () => void }) {
  const createCaptain = useAppStore((s) => s.createCaptain);
  const updateCaptain = useAppStore((s) => s.updateCaptain);
  const [form, setForm] = useState<CaptainInput>(EMPTY);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [credentialAttempt, setCredentialAttempt] = useState(0);
  const [submitting, setSubmitting] = useState(false);
  const set = (k: keyof CaptainInput, v: string) => setForm((f) => ({ ...f, [k]: v }));

  useEffect(() => {
    setForm(captain === 'new' || !captain ? EMPTY : { fullName: captain.fullName, phone: captain.phone, username: captain.username, password: captain.password });
    setErrors({});
  }, [captain]);

  const submit = () => {
    const e: Record<string, string> = {};
    if (!form.fullName.trim()) e.fullName = 'الاسم الكامل مطلوب';
    if (!form.phone.trim()) e.phone = 'رقم الهاتف مطلوب';
    else if (!isValidPhone(form.phone)) e.phone = PHONE_ERROR;
    const creds = credentialFieldErrors(form);
    if (creds.username) e.username = creds.username;
    if (creds.password) e.password = creds.password;
    setErrors(e);
    if (Object.keys(e).length) return setCredentialAttempt((n) => n + 1);
    if (submitting) return;
    setSubmitting(true);
    const result = captain === 'new' ? createCaptain(form) : updateCaptain((captain as Captain).id, form);
    setSubmitting(false);
    const field = !result.ok ? credentialFieldOf(result.code) : null;
    if (!result.ok && field) {
      setErrors((er) => ({ ...er, [field]: result.error }));
      return setCredentialAttempt((n) => n + 1);
    }
    if (reportResult(result, captain === 'new' ? 'تم إنشاء حساب الكابتن (تجريبي) — يبدأ بحالة غير متاح ورصيد صفر' : 'تم حفظ بيانات الكابتن')) onClose();
  };

  return (
    <Dialog
      open={!!captain}
      onClose={onClose}
      title={captain === 'new' ? 'إضافة كابتن' : 'تعديل بيانات الكابتن'}
      description={captain === 'new' ? 'التسجيل الذاتي غير متاح؛ الإدارة تنشئ حسابات الكباتن. طريقة الدخول للتطبيق قرار مفتوح.' : undefined}
      footer={
        <>
          <Button variant="outline" onClick={onClose}>إلغاء</Button>
          <Button onClick={submit} loading={submitting}>{captain === 'new' ? 'إنشاء الكابتن' : 'حفظ'}</Button>
        </>
      }
    >
      <div className="grid gap-4 md:grid-cols-2">
        <Field label="الاسم الكامل" required error={errors.fullName}>
          <Input value={form.fullName} onChange={(e) => set('fullName', e.target.value)} aria-invalid={!!errors.fullName} />
        </Field>
        <Field label="رقم الهاتف" required error={errors.phone} hint={PHONE_HINT}>
          <PhoneField value={form.phone} onChange={(v) => set('phone', v)} aria-invalid={!!errors.phone} />
        </Field>
        <AccountCredentialsFields
          idPrefix="captain"
          username={form.username}
          password={form.password}
          errors={{ username: errors.username, password: errors.password }}
          focusAttempt={credentialAttempt}
          onChange={(patch) => { setForm((f) => ({ ...f, ...patch })); setErrors((er) => ({ ...er, ...(patch.username !== undefined ? { username: '' } : { password: '' }) })); }}
        />
      </div>
    </Dialog>
  );
}
