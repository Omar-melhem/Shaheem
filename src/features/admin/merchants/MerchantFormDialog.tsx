import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAppStore, type MerchantInput } from '@/application/store';
import { isUnchangedLegacyLocation, pickupLocationError } from '@/application/merchantLocation';
import type { LatLng, Merchant } from '@/domain/types';
import { PHONE_ERROR, isValidPhone } from '@/domain/phone';
import { Button, Dialog, Field, Input, PhoneField, PHONE_HINT } from '@/shared/components/ui';
import { reportResult } from '@/shared/components/toast';
import { BusinessCategorySelect } from '@/features/merchants/BusinessCategorySelect';
import { MerchantLocationFields } from './MerchantLocationFields';

type FormState = Omit<MerchantInput, 'pickup'> & { pickup: LatLng | null };
const EMPTY: FormState = { businessName: '', category: null, contactName: '', phone: '', cityId: null, areaId: null, pickup: null, username: '', password: '' };

/** Add / edit a Merchant. The pickup comes from City → Area → pin; there is no typed address. */
export function MerchantFormDialog({ merchant, onClose }: { merchant: Merchant | 'new' | null; onClose: () => void }) {
  const createMerchant = useAppStore((s) => s.createMerchant);
  const updateMerchant = useAppStore((s) => s.updateMerchant);
  const areas = useAppStore((s) => s.areas);
  const [form, setForm] = useState<FormState>(EMPTY);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);
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
    if (!form.contactName.trim()) e.contactName = 'اسم جهة الاتصال مطلوب';
    if (!form.phone.trim()) e.phone = 'رقم الهاتف مطلوب';
    else if (!isValidPhone(form.phone)) e.phone = PHONE_ERROR;
    const location = { cityId: form.cityId, areaId: form.areaId, pickup: form.pickup as LatLng };
    if (!isUnchangedLegacyLocation(existing, location)) {
      const locationError = pickupLocationError(areas, location);
      if (locationError) e.location = locationError;
    }
    if (!form.username.trim()) e.username = 'اسم المستخدم مطلوب';
    if (form.password.length < 6) e.password = 'كلمة المرور 6 أحرف على الأقل';
    setErrors(e);
    if (Object.keys(e).length) return;
    setSubmitting(true);
    const input: MerchantInput = { ...form, pickup: form.pickup as LatLng };
    const result = existing ? updateMerchant(existing.id, input) : createMerchant(input);
    setSubmitting(false);
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
      description={existing ? undefined : 'في النسخة الإنتاجية تُرسل بيانات الدخول أو دعوة للتاجر — غير مفعّل في هذا النموذج.'}
      footer={
        <>
          <Button variant="outline" onClick={onClose}>إلغاء</Button>
          <Button onClick={submit} loading={submitting}>{existing ? 'حفظ' : 'إنشاء التاجر'}</Button>
        </>
      }
    >
      <div className="grid gap-4 md:grid-cols-2">
        <Field label="اسم النشاط التجاري" required error={errors.businessName}>
          <Input value={form.businessName} onChange={(e) => set('businessName', e.target.value)} aria-invalid={!!errors.businessName} />
        </Field>
        <Field label="فئة النشاط التجاري" required error={errors.category} htmlFor="merchant-category">
          <BusinessCategorySelect id="merchant-category" value={form.category} onChange={(c) => set('category', c)} aria-invalid={!!errors.category} />
        </Field>
        <Field label="المالك / جهة الاتصال" required error={errors.contactName}>
          <Input value={form.contactName} onChange={(e) => set('contactName', e.target.value)} aria-invalid={!!errors.contactName} />
        </Field>
        <Field label="رقم الهاتف" required error={errors.phone} hint={PHONE_HINT}>
          <PhoneField value={form.phone} onChange={(v) => set('phone', v)} aria-invalid={!!errors.phone} />
        </Field>
        <MerchantLocationFields
          value={{ cityId: form.cityId, areaId: form.areaId, pickup: form.pickup }}
          existing={existing}
          error={errors.location}
          onChange={(patch) => { setForm((f) => ({ ...f, ...patch })); setErrors((er) => ({ ...er, location: '' })); }}
        />
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
