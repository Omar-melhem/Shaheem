import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAppStore, type MerchantInput } from '@/app/state';
import { isUnchangedLegacyLocation, pickupLocationError } from '@/application/merchantLocation';
import { isLegacyMerchantCategory, type LatLng, type Merchant } from '@/domain/types';
import { PHONE_ERROR, isValidPhone } from '@/domain/phone';
import { AccountCredentialsFields, credentialFieldErrors, credentialFieldOf } from '../AccountCredentialsFields';
import { LEGACY_CATEGORY_NOTE, categoryLabel } from '@/features/merchants/categories';
import { Button, Dialog, Field, FormRow, FormSection, Input, PhoneField, PHONE_HINT } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { BusinessCategorySelect } from '@/features/merchants/BusinessCategorySelect';
import { MerchantLocationFields } from './MerchantLocationFields';

type FormState = Omit<MerchantInput, 'pickup'> & { pickup: LatLng | null };
const EMPTY: FormState = { businessName: '', category: null, phone: '', cityId: null, areaId: null, pickup: null, username: '', password: '' };

/** Add / edit a Merchant. The pickup comes from City → Area → pin; there is no typed address. */
export function MerchantFormDialog({ merchant, onClose }: { merchant: Merchant | 'new' | null; onClose: () => void }) {
  const createMerchant = useAppStore((s) => s.createMerchant);
  const updateMerchant = useAppStore((s) => s.updateMerchant);
  const areas = useAppStore((s) => s.areas);
  const [form, setForm] = useState<FormState>(EMPTY);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);
  const [invalidAttempt, setInvalidAttempt] = useState(0);
  const formRef = useRef<HTMLDivElement>(null);
  // After a failed submit, focus the first invalid field (inline errors explain each one).
  useEffect(() => {
    if (invalidAttempt) formRef.current?.querySelector<HTMLElement>('[aria-invalid="true"], [data-invalid="true"]')?.focus();
  }, [invalidAttempt]);
  const navigate = useNavigate();
  const existing = merchant && merchant !== 'new' ? merchant : undefined;

  useEffect(() => {
    if (merchant === 'new') setForm(EMPTY);
    else if (merchant) {
      const { id: _id, createdAt: _c, status: _s, address: _a, ...rest } = merchant;
      setForm(rest);
    }
    setErrors({});
  }, [merchant]);

  const set = <K extends keyof FormState>(k: K, v: FormState[K]) => setForm((f) => ({ ...f, [k]: v }));

  const submit = () => {
    const e: Record<string, string> = {};
    if (!form.businessName.trim()) e.businessName = 'اسم النشاط التجاري مطلوب';
    if (!form.category) e.category = 'اختر فئة النشاط التجاري';
    if (!form.phone.trim()) e.phone = 'رقم الهاتف مطلوب';
    else if (!isValidPhone(form.phone)) e.phone = PHONE_ERROR;
    const location = { cityId: form.cityId, areaId: form.areaId, pickup: form.pickup as LatLng };
    if (!isUnchangedLegacyLocation(existing, location)) {
      const locationError = pickupLocationError(areas, location);
      if (locationError) e.location = locationError;
    }
    const creds = credentialFieldErrors(form);
    if (creds.username) e.username = creds.username;
    if (creds.password) e.password = creds.password;
    setErrors(e);
    if (Object.keys(e).length) return setInvalidAttempt((n) => n + 1);
    if (submitting) return;
    setSubmitting(true);
    const input: MerchantInput = { ...form, pickup: form.pickup as LatLng };
    const result = existing ? updateMerchant(existing.id, input) : createMerchant(input);
    setSubmitting(false);
    // A username/password failure from the store is shown on its field; the other values stay as typed.
    const field = !result.ok ? credentialFieldOf(result.code) : null;
    if (!result.ok && field) {
      setErrors((er) => ({ ...er, [field]: result.error }));
      return setInvalidAttempt((n) => n + 1);
    }
    if (!reportResult(result, existing ? 'تم حفظ بيانات التاجر' : 'تم إنشاء التاجر — حدّد الآن مناطق التوصيل والأسعار')) return;
    onClose();
    // Spec §3: after registering a merchant, Admin configures its zones & pricing.
    if (!existing && result.ok && typeof result.value === 'string') navigate(`/admin/merchants/${result.value}/zones`);
  };

  return (
    <Dialog
      open={!!merchant}
      onClose={onClose}
      size="lg"
      title={existing ? 'تعديل بيانات التاجر' : 'إضافة تاجر'}
      description={existing ? undefined : 'بيانات الدخول في هذا النموذج تجريبية.'}
      footer={
        <>
          <Button variant="outline" className="flex-1 sm:flex-none" onClick={onClose}>إلغاء</Button>
          <Button className="flex-1 sm:flex-none" onClick={submit} loading={submitting}>{existing ? 'حفظ' : 'إنشاء التاجر'}</Button>
        </>
      }
    >
      <div ref={formRef} className="space-y-5">
        <FormSection title="معلومات النشاط التجاري">
          <FormRow>
            <Field label="اسم النشاط التجاري" required error={errors.businessName}>
              <Input value={form.businessName} onChange={(e) => set('businessName', e.target.value)} aria-invalid={!!errors.businessName} />
            </Field>
            <Field
              label="فئة النشاط التجاري"
              required
              error={errors.category}
              hint={form.category && isLegacyMerchantCategory(form.category) ? `الفئة الحالية «${categoryLabel(form.category)}». ${LEGACY_CATEGORY_NOTE}` : undefined}
              htmlFor="merchant-category"
            >
              <BusinessCategorySelect id="merchant-category" value={form.category} onChange={(c) => set('category', c)} aria-invalid={!!errors.category} />
            </Field>
          </FormRow>
          <FormRow>
            <Field label="رقم الهاتف" required error={errors.phone} hint={PHONE_HINT}>
              <PhoneField value={form.phone} onChange={(v) => set('phone', v)} aria-invalid={!!errors.phone} />
            </Field>
          </FormRow>
        </FormSection>
        <MerchantLocationFields
          value={{ cityId: form.cityId, areaId: form.areaId, pickup: form.pickup }}
          existing={existing}
          error={errors.location}
          onChange={(patch) => { setForm((f) => ({ ...f, ...patch })); setErrors((er) => ({ ...er, location: '' })); }}
        />
        <AccountCredentialsFields
          idPrefix="merchant"
          username={form.username}
          password={form.password}
          errors={{ username: errors.username, password: errors.password }}
          onChange={(patch) => { setForm((f) => ({ ...f, ...patch })); setErrors((er) => ({ ...er, ...(patch.username !== undefined ? { username: '' } : { password: '' }) })); }}
        />
      </div>
    </Dialog>
  );
}
