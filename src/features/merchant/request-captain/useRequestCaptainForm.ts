import { useEffect, useMemo, useRef, useState } from 'react';
import { merchantZoneOptions, resolveZoneFee } from '@/application/queries';
import { useAppStore } from '@/app/state';
import { AREA_UNAVAILABLE, LOCATION_REQUIRED, PIN_ON_SHARED_BORDER, PIN_OUTSIDE_COVERAGE, destinationPinError, matchAreaForPin } from '@/domain/destination';
import { CUSTOMER_PHONE_ERROR, isValidOptionalPhone } from '@/domain/phone';
import { parseOrderTotal } from '@/domain/orderTotal';
import { ammanDayKey, ammanWallTimeToEpoch } from '@/domain/time';
import type { ID, Merchant, RequestType } from '@/domain/types';
import { toast } from '@/shared/components/toast';
import type { CustomerLocation } from '../location/CustomerLocationSection';
import type { ReviewState } from './OrderReviewDialog';

interface FormState {
  requestType: RequestType;
  scheduleDate: string;
  scheduleTime: string;
  customerPhone: string;
  /** «مجموع الطلب» as typed; blank = not provided. */
  orderTotal: string;
  areaId: ID | null;
  location: CustomerLocation | null;
}
type Errors = Partial<Record<keyof FormState | 'schedule', string>>;

const EMPTY_FORM: FormState = { requestType: 'immediate', scheduleDate: '', scheduleTime: '', customerPhone: '', orderTotal: '', areaId: null, location: null };
/** Stands in for the network round-trip so the progress state is real to the user (demo, no backend). */
const SUBMIT_PAUSE_MS = 400;

/** Pickup time for a scheduled request, or an error message. Amman time, strictly in the future. */
function scheduledPickup(form: FormState, now: number): { at: number } | { error: string } {
  if (!form.scheduleDate || !form.scheduleTime) return { error: 'حدّد تاريخ ووقت وصول الكابتن إلى المتجر' };
  const at = ammanWallTimeToEpoch(form.scheduleDate, form.scheduleTime);
  if (at === null) return { error: 'التاريخ أو الوقت غير صالح' };
  if (at <= now) return { error: 'اختر وقتاً في المستقبل' };
  return { at };
}

/**
 * Request Captain flow: form state, validation, the review step and the single create-order call.
 * «مجموع الطلب» is optional and never affects the fee (owner, 2026-11-25); a scheduled request goes to
 * Admin only (CR v1.4 §6).
 */
export function useRequestCaptainForm(merchant: Merchant) {
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
  const coverage = useAppStore((s) => s.coverage);
  const createOrder = useAppStore((s) => s.createOrder);
  const [form, setForm] = useState<FormState>(EMPTY_FORM);
  const [errors, setErrors] = useState<Errors>({});
  const [pinNotice, setPinNotice] = useState<string | null>(null);
  const [review, setReview] = useState<ReviewState | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [resetCount, setResetCount] = useState(0);
  const submitLock = useRef(false);
  const submitTimer = useRef<number>();

  useEffect(() => () => window.clearTimeout(submitTimer.current), []);

  const areaOptions = useMemo(() => merchantZoneOptions({ areas, prices, coverage }, merchant.id), [areas, prices, coverage, merchant.id]);
  const selectedArea = useMemo(() => areas.find((a) => a.id === form.areaId) ?? null, [areas, form.areaId]);
  const resolution = useMemo(
    () => (form.areaId ? resolveZoneFee({ areas, prices, coverage }, merchant.id, form.areaId) : null),
    [areas, prices, coverage, merchant.id, form.areaId],
  );
  // Derived, so the pin is always checked against the current area.
  const pinError = selectedArea && form.location ? destinationPinError(selectedArea, form.location.position) : null;
  const areaError = errors.areaId ?? (resolution && resolution.kind !== 'ok' ? AREA_UNAVAILABLE : undefined);
  const minScheduleDate = ammanDayKey(Date.now());

  const set = <K extends keyof FormState>(key: K, value: FormState[K]) => {
    setForm((f) => ({ ...f, [key]: value }));
    setErrors((e) => ({ ...e, [key]: undefined }));
  };
  const setSchedule = (patch: { date?: string; time?: string }) => {
    setForm((f) => ({ ...f, scheduleDate: patch.date ?? f.scheduleDate, scheduleTime: patch.time ?? f.scheduleTime }));
    setErrors((e) => ({ ...e, schedule: undefined }));
  };

  /** A pin that does not fit the newly chosen area is removed and the Merchant is told. */
  const selectArea = (areaId: ID | null) => {
    const area = areas.find((a) => a.id === areaId);
    const dropPin = !!area && !!form.location && destinationPinError(area, form.location.position) !== null;
    setForm((f) => ({ ...f, areaId, location: dropPin ? null : f.location }));
    setErrors((e) => ({ ...e, areaId: undefined }));
    setPinNotice(dropPin ? `أُزيل الدبوس السابق لأنه لا يطابق منطقة «${area.name}». يمكنك تحديد موقع جديد، وهذا اختياري.` : null);
  };

  /**
   * Sets the optional exact pin. Dropped before an area is chosen, the pin satisfies the location
   * requirement only when it falls inside exactly one of the Merchant's areas — that area (and its
   * fixed fee) is then selected and the Merchant is told. Otherwise the pin is not kept.
   */
  const setPin = (location: CustomerLocation | null) => {
    if (location && !form.areaId) {
      const match = matchAreaForPin(areaOptions.map((o) => o.area), location.position);
      if (match.kind !== 'one') {
        setErrors((e) => ({ ...e, areaId: match.kind === 'ambiguous' ? PIN_ON_SHARED_BORDER : PIN_OUTSIDE_COVERAGE }));
        setPinNotice(null);
        return;
      }
      const detected = match.area;
      const label = areaOptions.find((o) => o.area.id === detected.id)?.label ?? detected.name;
      setForm((f) => ({ ...f, areaId: detected.id, location }));
      setErrors((e) => ({ ...e, areaId: undefined }));
      setPinNotice(`حُدّدت منطقة التوصيل تلقائياً من الموقع: «${label}».`);
      return;
    }
    setForm((f) => ({ ...f, location }));
    setPinNotice(null);
  };

  /** Inline check when the phone field loses focus: blank is fine (optional), anything else must be valid. */
  const validatePhone = () => {
    setErrors((e) => ({ ...e, customerPhone: isValidOptionalPhone(form.customerPhone) ? undefined : CUSTOMER_PHONE_ERROR }));
  };

  /** Inline check when «مجموع الطلب» loses focus: blank is fine (optional). */
  const validateOrderTotal = () => {
    const total = parseOrderTotal(form.orderTotal);
    setErrors((e) => ({ ...e, orderTotal: total.ok ? undefined : total.error }));
  };

  /** Validates everything and opens the review; returns false when a field needs fixing. */
  const openReview = (): boolean => {
    const next: Errors = {};
    if (!isValidOptionalPhone(form.customerPhone)) next.customerPhone = CUSTOMER_PHONE_ERROR;
    const total = parseOrderTotal(form.orderTotal);
    if (!total.ok) next.orderTotal = total.error;
    if (!form.areaId) next.areaId = LOCATION_REQUIRED;
    let scheduledAt: number | undefined;
    if (form.requestType === 'scheduled') {
      const check = scheduledPickup(form, Date.now());
      if ('error' in check) next.schedule = check.error;
      else scheduledAt = check.at;
    }
    setErrors(next);
    if (Object.keys(next).length > 0 || pinError || resolution?.kind !== 'ok') return false;
    setSubmitError(null);
    setReview({ fee: resolution.price, requestType: form.requestType, scheduledPickupAt: scheduledAt, orderTotal: total.ok ? total.fils : undefined });
    return true;
  };

  const closeReview = () => {
    if (!submitLock.current) setReview(null);
  };

  const confirm = () => {
    if (!review || !form.areaId || submitLock.current) return;
    submitLock.current = true;
    setSubmitting(true);
    setSubmitError(null);
    const { areaId, location } = form;
    submitTimer.current = window.setTimeout(() => {
      const result = createOrder(merchant.id, {
        customerPhone: form.customerPhone.trim() || undefined,
        areaId,
        location: location?.position,
        placeName: location?.placeName,
        requestType: review.requestType,
        scheduledPickupAt: review.scheduledPickupAt,
        expectedFee: review.fee,
        orderTotal: review.orderTotal,
      });
      submitLock.current = false;
      setSubmitting(false);
      if (result.ok) {
        const scheduled = review.requestType === 'scheduled';
        setReview(null);
        setForm(EMPTY_FORM);
        setPinNotice(null);
        setResetCount((n) => n + 1);
        // Truthful wording: nothing here means a Captain has accepted (CR v1.4 §6.1).
        toast.success(scheduled ? 'تم إرسال الطلب المؤجل' : 'تم تأكيد طلب الكابتن بنجاح', {
          description: scheduled
            ? `الطلب رقم ${result.value.reference} بانتظار تنسيق الإدارة لكابتن في الموعد المطلوب.`
            : `تم إنشاء الطلب رقم ${result.value.reference} وإرساله إلى النظام.`,
          durationMs: 6000,
        });
      } else if (result.code === 'fee_changed' && result.currentFee !== undefined) {
        setReview({ ...review, fee: result.currentFee, changedFrom: review.fee }); // re-confirm the new fee (Spec §10)
      } else {
        setSubmitError(result.error);
      }
    }, SUBMIT_PAUSE_MS);
  };

  return {
    form, errors, set, setSchedule, minScheduleDate, areaOptions, selectedArea, resolution, areaError, pinError, pinNotice, selectArea, setPin, validatePhone, validateOrderTotal,
    resetCount, review, submitting, submitError, openReview, closeReview, confirm,
  };
}
