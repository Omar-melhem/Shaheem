import { useEffect, useRef, useState } from 'react';
import { useAppStore, type CaptainInput } from '@/app/state';
import type { Captain } from '@/domain/types';
import { PHONE_ERROR, isValidPhone } from '@/domain/phone';
import { AccountCredentialsFields, credentialFieldErrors, credentialFieldOf } from '../AccountCredentialsFields';
import { Button, Dialog, Field, FormRow, FormSection, Input, PhoneField, PHONE_HINT } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';

const EMPTY: CaptainInput = { fullName: '', phone: '', username: '', password: '' };

/** Add / edit a Captain: name, phone and demo credentials only (no vehicle data). */
export function CaptainFormDialog({ captain, onClose }: { captain: Captain | 'new' | null; onClose: () => void }) {
  const createCaptain = useAppStore((s) => s.createCaptain);
  const updateCaptain = useAppStore((s) => s.updateCaptain);
  const [form, setForm] = useState<CaptainInput>(EMPTY);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [invalidAttempt, setInvalidAttempt] = useState(0);
  const formRef = useRef<HTMLDivElement>(null);
  // After a failed submit, focus the first invalid field (inline errors explain each one).
  useEffect(() => {
    if (invalidAttempt) formRef.current?.querySelector<HTMLElement>('[aria-invalid="true"]')?.focus();
  }, [invalidAttempt]);
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
    if (Object.keys(e).length) return setInvalidAttempt((n) => n + 1);
    if (submitting) return;
    setSubmitting(true);
    const result = captain === 'new' ? createCaptain(form) : updateCaptain((captain as Captain).id, form);
    setSubmitting(false);
    const field = !result.ok ? credentialFieldOf(result.code) : null;
    if (!result.ok && field) {
      setErrors((er) => ({ ...er, [field]: result.error }));
      return setInvalidAttempt((n) => n + 1);
    }
    if (reportResult(result, captain === 'new' ? 'تم إنشاء حساب الكابتن (تجريبي) — يبدأ بحالة غير متاح ورصيد صفر' : 'تم حفظ بيانات الكابتن')) onClose();
  };

  return (
    <Dialog
      open={!!captain}
      onClose={onClose}
      title={captain === 'new' ? 'إضافة كابتن' : 'تعديل بيانات الكابتن'}
      description={captain === 'new' ? 'يبدأ الكابتن بحالة «غير متاح» ورصيد صفر.' : undefined}
      footer={
        <>
          <Button variant="outline" className="flex-1 sm:flex-none" onClick={onClose}>إلغاء</Button>
          <Button className="flex-1 sm:flex-none" onClick={submit} loading={submitting}>{captain === 'new' ? 'إنشاء الكابتن' : 'حفظ'}</Button>
        </>
      }
    >
      <div ref={formRef} className="space-y-5">
        <FormSection title="بيانات الكابتن">
          <FormRow>
            <Field label="الاسم الكامل" required error={errors.fullName}>
              <Input value={form.fullName} onChange={(e) => set('fullName', e.target.value)} aria-invalid={!!errors.fullName} />
            </Field>
            <Field label="رقم الهاتف" required error={errors.phone} hint={PHONE_HINT}>
              <PhoneField value={form.phone} onChange={(v) => set('phone', v)} aria-invalid={!!errors.phone} />
            </Field>
          </FormRow>
        </FormSection>
        <AccountCredentialsFields
          idPrefix="captain"
          username={form.username}
          password={form.password}
          errors={{ username: errors.username, password: errors.password }}
          onChange={(patch) => { setForm((f) => ({ ...f, ...patch })); setErrors((er) => ({ ...er, ...(patch.username !== undefined ? { username: '' } : { password: '' }) })); }}
        />
      </div>
    </Dialog>
  );
}
