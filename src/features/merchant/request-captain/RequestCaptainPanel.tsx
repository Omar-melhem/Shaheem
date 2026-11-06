import { useEffect, useRef, useState, type ReactNode } from 'react';
import { AlertTriangle, Lock, Send } from 'lucide-react';
import { PINNED_LOCATION_LABEL } from '@/domain/destination';
import type { Merchant } from '@/domain/types';
import { formatMoney } from '@/domain/money';
import { Button, Card, Field, Input, PhoneField, PHONE_HINT } from '@/shared/components/ui';
import { CustomerLocationSection } from '../location/CustomerLocationSection';
import { OrderReviewDialog } from './OrderReviewDialog';
import { OrderValueField } from './OrderValueField';
import { useRequestCaptainForm } from './useRequestCaptainForm';

/**
 * Merchant "Request Captain" form. The Merchant chooses a delivery area from the list and
 * may add an exact pin. The read-only fee comes from Merchant + area in the application
 * layer and is re-checked at confirmation.
 */
export function RequestCaptainPanel({ merchant }: { merchant: Merchant }) {
  const request = useRequestCaptainForm(merchant);
  const { form, errors, set, resolution } = request;
  const hasAreas = request.areaOptions.length > 0;
  const blocked = merchant.status !== 'active' || !hasAreas;

  const fieldsRef = useRef<HTMLFieldSetElement>(null);
  const [invalidAttempts, setInvalidAttempts] = useState(0);
  useEffect(() => {
    if (invalidAttempts > 0) fieldsRef.current?.querySelector<HTMLElement>('[aria-invalid="true"], [data-invalid="true"]')?.focus();
  }, [invalidAttempts]);

  const requestCaptain = () => {
    if (!request.openReview()) setInvalidAttempts((n) => n + 1);
  };

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
      ) : !hasAreas ? (
        <BlockedNotice>لا توجد مناطق توصيل مفعّلة لحسابك بعد. يرجى التواصل مع إدارة شهم لإعداد المناطق والأسعار.</BlockedNotice>
      ) : null}

      <fieldset ref={fieldsRef} disabled={blocked} className="space-y-5 p-5 disabled:opacity-60">
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label="هاتف العميل" optional error={errors.customerPhone} hint={PHONE_HINT}>
            <PhoneField value={form.customerPhone} onChange={(v) => set('customerPhone', v)} aria-invalid={!!errors.customerPhone} />
          </Field>
          <Field label="اسم العميل" optional>
            <Input value={form.customerName} onChange={(e) => set('customerName', e.target.value)} autoComplete="off" />
          </Field>
        </div>

        <CustomerLocationSection
          key={request.resetCount}
          options={request.areaOptions}
          areaId={form.areaId}
          area={request.selectedArea}
          areaError={request.areaError}
          location={form.location}
          pinError={request.pinError}
          pinNotice={request.pinNotice}
          pickup={merchant.pickup}
          onSelectArea={request.selectArea}
          onPinChange={request.setPin}
        />

        <OrderValueField value={form.mealValue} error={errors.mealValue} onChange={(v) => set('mealValue', v)} onBlur={request.normalizeOrderValue} />

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
            <Button size="lg" onClick={requestCaptain}>طلب كابتن</Button>
          </div>
          <p className="mt-1 text-xs text-ink-muted">تُحدَّد رسوم التوصيل تلقائياً من شهم حسب منطقة التوصيل.</p>
        </div>
      </fieldset>

      <OrderReviewDialog
        review={request.review}
        details={{
          pickupName: merchant.businessName,
          pickupAddress: merchant.address,
          areaName: request.selectedArea?.name ?? '',
          exactLocation: form.location ? form.location.placeName ?? PINNED_LOCATION_LABEL : null,
          customerName: form.customerName.trim() || undefined,
          customerPhone: form.customerPhone.trim() || undefined,
        }}
        submitting={request.submitting}
        error={request.submitError}
        onClose={request.closeReview}
        onConfirm={request.confirm}
      />
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
