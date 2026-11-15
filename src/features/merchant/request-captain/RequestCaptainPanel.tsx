import { useEffect, useRef, useState, type ReactNode } from 'react';
import { AlertTriangle, Lock, MapPin, Send } from 'lucide-react';
import { PINNED_LOCATION_LABEL } from '@/domain/destination';
import type { Merchant } from '@/domain/types';
import { formatMoney } from '@/domain/money';
import { Button, Card, Field, PhoneField, PHONE_HINT } from '@/shared/components/ui';
import { CustomerLocationSection } from '../location/CustomerLocationSection';
import { OrderReviewDialog } from './OrderReviewDialog';
import { RequestTypeSelector } from './RequestTypeSelector';
import { ScheduleFields } from './ScheduleFields';
import { useRequestCaptainForm } from './useRequestCaptainForm';

/**
 * Merchant "Request Captain" form on one page, in three sections: request type → delivery
 * information → order details with the fee and the main action. No customer name and no goods
 * value (CR v1.4 §4). The read-only fee comes from Merchant + area in the application layer and
 * is re-checked when the order is created, so a stale price can never be submitted.
 */
export function RequestCaptainPanel({ merchant }: { merchant: Merchant }) {
  const request = useRequestCaptainForm(merchant);
  const { form, errors, set, resolution } = request;
  const hasAreas = request.areaOptions.length > 0;
  const blocked = merchant.status !== 'active' || !hasAreas;
  const fee = resolution?.kind === 'ok' ? resolution.price : null;
  const areaLabel = request.areaOptions.find((o) => o.area.id === form.areaId)?.label ?? request.selectedArea?.name ?? '';

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
        <p className="flex items-center gap-1.5 text-sm text-ink-muted">
          <MapPin className="h-4 w-4 shrink-0 text-primary" aria-hidden /> الاستلام من {merchant.businessName} · {merchant.address}
        </p>
      </div>

      {merchant.status !== 'active' ? (
        <BlockedNotice>حسابك غير مفعّل حالياً. يرجى التواصل مع إدارة شهم.</BlockedNotice>
      ) : !hasAreas ? (
        <BlockedNotice>لا توجد مناطق توصيل مفعّلة لحسابك بعد. يرجى التواصل مع إدارة شهم لإعداد المناطق والأسعار.</BlockedNotice>
      ) : null}

      <fieldset ref={fieldsRef} disabled={blocked} className="disabled:opacity-60">
        <FormSection step={1} title="نوع الطلب" badge="الطلب الفوري افتراضياً">
          <RequestTypeSelector value={form.requestType} onChange={(v) => set('requestType', v)} />
          {form.requestType === 'scheduled' && (
            <ScheduleFields date={form.scheduleDate} time={form.scheduleTime} minDate={request.minScheduleDate} error={errors.schedule} onChange={request.setSchedule} />
          )}
        </FormSection>

        <FormSection step={2} title="بيانات التوصيل">
          <Field label="رقم هاتف العميل" optional error={errors.customerPhone} hint={PHONE_HINT}>
            <PhoneField value={form.customerPhone} onChange={(v) => set('customerPhone', v)} aria-invalid={!!errors.customerPhone} />
          </Field>
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
        </FormSection>

        <FormSection step={3} title="تفاصيل الطلب">
          <div className="space-y-1">
            <div className="flex items-center justify-between gap-3">
              <p className="flex items-center gap-1 text-sm text-ink-soft">
                <Lock className="h-3.5 w-3.5" aria-hidden /> رسوم التوصيل{fee !== null && areaLabel ? ` إلى ${areaLabel}` : ''}
              </p>
              <p className="text-lg font-extrabold text-ink" aria-live="polite">{fee !== null ? formatMoney(fee) : '—'}</p>
            </div>
            <p className="text-xs text-ink-muted">
              {fee !== null ? 'تُحدَّد تلقائياً من شهم حسب المنطقة، وتُثبَّت على الطلب عند التأكيد.' : 'اختر منطقة التوصيل لعرض الرسوم المحددة من شهم.'}
            </p>
          </div>
        </FormSection>

        {/* Main action: in the card on desktop, a sticky bar with safe-area padding on small screens. */}
        <div className="sticky bottom-0 z-10 rounded-b-2xl bg-white/95 px-5 pb-[calc(env(safe-area-inset-bottom)+0.75rem)] pt-3 backdrop-blur lg:static lg:bg-white lg:pb-5">
          <Button size="lg" className="w-full" onClick={requestCaptain} icon={<Send className="h-4 w-4" />}>
            تأكيد طلب كابتن{fee !== null ? ` · ${formatMoney(fee)}` : ''}
          </Button>
        </div>
      </fieldset>

      <OrderReviewDialog
        review={request.review}
        details={{
          pickupName: merchant.businessName,
          pickupAddress: merchant.address,
          areaName: areaLabel,
          exactLocation: form.location ? form.location.placeName ?? PINNED_LOCATION_LABEL : null,
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

function FormSection({ step, title, badge, children }: { step: number; title: string; badge?: string; children: ReactNode }) {
  const id = `request-section-${step}`;
  return (
    <section aria-labelledby={id} className="space-y-4 border-b border-cream-dark px-5 py-5">
      <div className="flex items-center justify-between gap-2">
        <h3 id={id} className="text-sm font-extrabold text-ink">
          <span className="font-mono text-ink-soft" aria-hidden>{String(step).padStart(2, '0')} — </span>
          {title}
        </h3>
        {badge && <span className="rounded-full bg-secondary-50 px-2.5 py-0.5 text-[11px] font-bold text-secondary">{badge}</span>}
      </div>
      {children}
    </section>
  );
}

function BlockedNotice({ children }: { children: ReactNode }) {
  return (
    <p className="mx-5 mt-5 flex items-start gap-2 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-800" role="alert">
      <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" /> {children}
    </p>
  );
}
