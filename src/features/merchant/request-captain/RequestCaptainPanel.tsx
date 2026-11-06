import { useMemo, useState, type ReactNode } from 'react';
import { AlertTriangle, Lock, Send } from 'lucide-react';
import { useAppStore } from '@/application/store';
import { merchantZoneOptions, resolveLocationFee } from '@/application/queries';
import type { Merchant } from '@/domain/types';
import { formatMoney, parseJodInput } from '@/domain/money';
import { Button, Card, Field, Input, PhoneField, PHONE_HINT } from '@/shared/components/ui';
import { reportResult, toast } from '@/shared/components/toast';
import { PHONE_ERROR, isValidOptionalPhone } from '@/domain/phone';
import { CustomerLocationSection, OUTSIDE_MSG, UNAVAILABLE_MSG, type CustomerLocation } from './location/CustomerLocationSection';
import { OrderReviewDialog, type ReviewState } from './OrderReviewDialog';

interface FormState {
  customerPhone: string;
  customerName: string;
  location: CustomerLocation | null;
  mealValue: string;
}
type Errors = Partial<Record<keyof FormState, string>>;
const EMPTY_FORM: FormState = { customerPhone: '', customerName: '', location: null, mealValue: '' };

/**
 * Merchant "Request Captain" form. The Merchant pins the customer like in a delivery
 * app (search or map); the zone and the read-only fee are derived from the pin by the
 * application layer and re-checked at confirmation.
 */
export function RequestCaptainPanel({ merchant, onCreated }: { merchant: Merchant; onCreated: (reference: string) => void }) {
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const createOrder = useAppStore((s) => s.createOrder);
  const [form, setForm] = useState<FormState>(EMPTY_FORM);
  const [errors, setErrors] = useState<Errors>({});
  const [review, setReview] = useState<ReviewState | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const zoneOptions = useMemo(() => merchantZoneOptions({ areas, prices }, merchant.id), [areas, prices, merchant.id]);
  const hasZones = zoneOptions.length > 0;
  const searchableAreas = useMemo(() => zoneOptions.map((o) => o.area).filter((a) => a.polygon.length >= 3), [zoneOptions]);
  const resolution = useMemo(
    () => (form.location ? resolveLocationFee({ areas, prices }, merchant.id, form.location.position) : null),
    [areas, prices, merchant.id, form.location],
  );
  const mealValue = form.mealValue.trim() ? parseJodInput(form.mealValue) : null;
  const blocked = merchant.status !== 'active' || !hasZones;

  const set = <K extends keyof FormState>(k: K, v: FormState[K]) => {
    setForm((f) => ({ ...f, [k]: v }));
    setErrors((e) => ({ ...e, [k]: undefined }));
  };

  const validate = () => {
    const e: Errors = {};
    if (!isValidOptionalPhone(form.customerPhone)) e.customerPhone = PHONE_ERROR;
    if (!form.location) e.location = 'حدّد موقع العميل بالبحث أو على الخريطة';
    else if (resolution?.kind !== 'ok') e.location = resolution?.kind === 'outside' ? OUTSIDE_MSG : UNAVAILABLE_MSG;
    if (!form.mealValue.trim()) e.mealValue = 'قيمة الطلب مطلوبة';
    else if (mealValue === null || mealValue <= 0) e.mealValue = 'يرجى إدخال قيمة طلب صحيحة';
    setErrors(e);
    return Object.keys(e).length === 0;
  };

  const openReview = () => {
    if (validate() && resolution?.kind === 'ok') setReview({ fee: resolution.price });
  };

  const confirm = () => {
    if (!review || submitting || !form.location || mealValue === null) return;
    setSubmitting(true);
    const result = createOrder(merchant.id, {
      customerPhone: form.customerPhone,
      customerName: form.customerName,
      location: form.location.position,
      placeName: form.location.placeName,
      mealValue,
      expectedFee: review.fee,
    });
    setSubmitting(false);
    if (result.ok) {
      toast.success(`تم إرسال الطلب ${result.value.reference}`);
      setReview(null);
      setForm(EMPTY_FORM);
      onCreated(result.value.reference);
    } else if (result.code === 'fee_changed' && result.currentFee !== undefined) {
      setReview({ fee: result.currentFee, changedFrom: review.fee }); // re-confirm the new fee (Spec §10)
    } else {
      reportResult(result);
      setReview(null);
    }
  };

  const reviewRows: Array<[string, ReactNode]> = [
    ['الاستلام من', merchant.businessName],
    ...(form.customerPhone.trim() ? [['هاتف العميل', <span dir="ltr">{form.customerPhone}</span>] as [string, ReactNode]] : []),
    ...(form.customerName.trim() ? [['اسم العميل', form.customerName] as [string, ReactNode]] : []),
    ['المنطقة', resolution?.kind === 'ok' ? resolution.area.name : '—'],
    ...(form.location?.placeName ? [['المكان', form.location.placeName] as [string, ReactNode]] : []),
    ...(mealValue !== null ? [['قيمة الطلب', formatMoney(mealValue)] as [string, ReactNode]] : []),
  ];

  return (
    <Card className="overflow-visible">
      <div className="border-b border-cream-dark px-5 py-4">
        <h2 className="flex items-center gap-2 text-lg font-extrabold text-ink">
          <Send className="h-5 w-5 text-primary" /> طلب كابتن
        </h2>
        <p className="text-sm text-ink-muted">موقع الاستلام يُؤخذ تلقائياً من ملفك: {merchant.address}</p>
      </div>

      {merchant.status !== 'active' ? (
        <BlockedNotice>حسابك غير مفعّل حالياً. يرجى التواصل مع إدارة شهم.</BlockedNotice>
      ) : !hasZones ? (
        <BlockedNotice>لا توجد مناطق توصيل مفعّلة لحسابك بعد. يرجى التواصل مع إدارة شهم لإعداد المناطق والأسعار.</BlockedNotice>
      ) : null}

      <fieldset disabled={blocked} className="space-y-5 p-5 disabled:opacity-60">
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="هاتف العميل" optional error={errors.customerPhone} hint={PHONE_HINT}>
            <PhoneField value={form.customerPhone} onChange={(v) => set('customerPhone', v)} aria-invalid={!!errors.customerPhone} />
          </Field>
          <Field label="اسم العميل" optional>
            <Input value={form.customerName} onChange={(e) => set('customerName', e.target.value)} autoComplete="off" />
          </Field>
        </div>

        <CustomerLocationSection value={form.location} pickup={merchant.pickup} areas={searchableAreas} resolution={resolution} error={errors.location} onChange={(loc) => set('location', loc)} />

        <Field label="قيمة الطلب *" error={errors.mealValue} hint="بالدينار الأردني، حتى ثلاث خانات عشرية." className="sm:max-w-[50%]">
          <Input value={form.mealValue} onChange={(e) => set('mealValue', e.target.value)} inputMode="decimal" dir="ltr" className="rtl:text-right" placeholder="مثال: 12.500" required aria-invalid={!!errors.mealValue} />
        </Field>

        <div className="rounded-xl bg-cream px-4 py-3">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className="flex items-center gap-1 text-xs font-bold text-ink-muted">
                <Lock className="h-3.5 w-3.5" /> رسوم التوصيل
              </p>
              <p className="text-3xl font-extrabold text-primary" aria-live="polite">
                {resolution?.kind === 'ok' ? formatMoney(resolution.price) : '—'}
              </p>
            </div>
            <Button size="lg" onClick={openReview}>مراجعة الطلب</Button>
          </div>
          <p className="mt-1 text-xs text-ink-muted">تُحدَّد رسوم التوصيل تلقائياً من شهم حسب موقع العميل.</p>
        </div>
      </fieldset>

      <OrderReviewDialog review={review} rows={reviewRows} submitting={submitting} onClose={() => setReview(null)} onConfirm={confirm} />
    </Card>
  );
}

function BlockedNotice({ children }: { children: ReactNode }) {
  return (
    <p className="mx-5 mt-5 flex items-start gap-2 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">
      <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" /> {children}
    </p>
  );
}
