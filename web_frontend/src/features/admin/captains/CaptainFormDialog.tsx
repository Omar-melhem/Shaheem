import { useEffect, useState } from 'react';
import { useAppStore, type CaptainInput } from '@/application/store';
import type { Captain } from '@/domain/types';
import { PHONE_ERROR, isValidPhone } from '@/domain/phone';
import { Button, Dialog, Field, Input, PhoneField, PHONE_HINT } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';

const EMPTY: CaptainInput = { fullName: '', phone: '', username: '', password: '' };

/** Add / edit a Captain: name, phone and demo credentials only (no vehicle data). */
export function CaptainFormDialog({ captain, onClose }: { captain: Captain | 'new' | null; onClose: () => void }) {
  const createCaptain = useAppStore((s) => s.createCaptain);
  const updateCaptain = useAppStore((s) => s.updateCaptain);
  const [form, setForm] = useState<CaptainInput>(EMPTY);
  const [errors, setErrors] = useState<Record<string, string>>({});
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
    if (!form.username.trim()) e.username = 'اسم المستخدم مطلوب';
    if (form.password.length < 6) e.password = 'كلمة المرور 6 أحرف على الأقل';
    setErrors(e);
    if (Object.keys(e).length) return;
    const result = captain === 'new' ? createCaptain(form) : updateCaptain((captain as Captain).id, form);
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
          <Button onClick={submit}>{captain === 'new' ? 'إنشاء الكابتن' : 'حفظ'}</Button>
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
        <div className="rounded-xl border border-dashed border-sand-dark/50 bg-sand-light/20 p-4 md:col-span-2">
          <p className="mb-3 text-sm font-bold text-ink">بيانات الدخول (تجريبية)</p>
          <div className="grid gap-4 md:grid-cols-2">
            <Field label="اسم المستخدم" required error={errors.username}>
              <Input value={form.username} onChange={(e) => set('username', e.target.value)} dir="ltr" autoComplete="off" aria-invalid={!!errors.username} />
            </Field>
            <Field label="كلمة المرور" required error={errors.password} hint="6 أحرف على الأقل">
              <Input value={form.password} onChange={(e) => set('password', e.target.value)} dir="ltr" autoComplete="off" aria-invalid={!!errors.password} />
            </Field>
          </div>
        </div>
      </div>
    </Dialog>
  );
}
