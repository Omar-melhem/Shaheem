import { useEffect, useMemo, useRef, useState } from 'react';
import { merchantZoneOptions, resolveZoneFee } from '@/application/queries';
import { useAppStore } from '@/application/store';
import { AREA_REQUIRED, AREA_UNAVAILABLE, destinationPinError } from '@/domain/destination';
import { checkOrderValue } from '@/domain/orderValue';
import { PHONE_ERROR, isValidOptionalPhone } from '@/domain/phone';
import type { ID, Merchant } from '@/domain/types';
import { toast } from '@/shared/components/toast';
import type { CustomerLocation } from '../location/CustomerLocationSection';
import type { ReviewState } from './OrderReviewDialog';

interface FormState {
  customerPhone: string;
  customerName: string;
  areaId: ID | null;
  location: CustomerLocation | null;
  mealValue: string;
}
type Errors = Partial<Record<keyof FormState, string>>;

const EMPTY_FORM: FormState = { customerPhone: '', customerName: '', areaId: null, location: null, mealValue: '' };
/** Stands in for the network round-trip so the progress state is real to the user (demo, no backend). */
const SUBMIT_PAUSE_MS = 400;

/** Request Captain flow: form state, validation, the review step and the single create-order call. */
export function useRequestCaptainForm(merchant: Merchant) {
  const areas = useAppStore((s) => s.areas);
  const prices = useAppStore((s) => s.prices);
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

  const areaOptions = useMemo(() => merchantZoneOptions({ areas, prices }, merchant.id), [areas, prices, merchant.id]);
  const selectedArea = useMemo(() => areas.find((a) => a.id === form.areaId) ?? null, [areas, form.areaId]);
  const resolution = useMemo(
    () => (form.areaId ? resolveZoneFee({ areas, prices }, merchant.id, form.areaId) : null),
    [areas, prices, merchant.id, form.areaId],
  );
  // Derived, so the pin is always checked against the current area and its current boundary.
  const pinError = selectedArea && form.location ? destinationPinError(selectedArea, form.location.position) : null;
  const areaError = errors.areaId ?? (resolution && resolution.kind !== 'ok' ? AREA_UNAVAILABLE : undefined);

  const set = <K extends keyof FormState>(key: K, value: FormState[K]) => {
    setForm((f) => ({ ...f, [key]: value }));
    setErrors((e) => ({ ...e, [key]: undefined }));
  };

  /** A pin that does not fit the newly chosen area is removed and the Merchant is told. */
  const selectArea = (areaId: ID | null) => {
    const area = areas.find((a) => a.id === areaId);
    const dropPin = !!area && !!form.location && destinationPinError(area, form.location.position) !== null;
    setForm((f) => ({ ...f, areaId, location: dropPin ? null : f.location }));
    setErrors((e) => ({ ...e, areaId: undefined }));
    setPinNotice(dropPin ? `أُزيل الدبوس السابق لأنه لا يطابق منطقة «${area.name}». يمكنك تحديد موقع جديد داخلها، وهذا اختياري.` : null);
  };

  const setPin = (location: CustomerLocation | null) => {
    setForm((f) => ({ ...f, location }));
    setPinNotice(null);
  };

  const normalizeOrderValue = () => {
    const check = checkOrderValue(form.mealValue);
    if (check.ok) set('mealValue', check.display);
    else setErrors((e) => ({ ...e, mealValue: check.error }));
    return check;
  };

  /** Validates everything and opens the review; returns false when a field needs fixing. */
  const openReview = (): boolean => {
    const next: Errors = {};
    if (!isValidOptionalPhone(form.customerPhone)) next.customerPhone = PHONE_ERROR;
    if (!form.areaId) next.areaId = AREA_REQUIRED;
    const orderValue = normalizeOrderValue();
    if (!orderValue.ok) next.mealValue = orderValue.error;
    setErrors(next);
    if (Object.keys(next).length > 0 || pinError || !orderValue.ok || resolution?.kind !== 'ok') return false;
    setSubmitError(null);
    setReview({ fee: resolution.price, orderValue: orderValue.fils });
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
        customerPhone: form.customerPhone,
        customerName: form.customerName,
        areaId,
        location: location?.position,
        placeName: location?.placeName,
        mealValue: review.orderValue,
        expectedFee: review.fee,
      });
      submitLock.current = false;
      setSubmitting(false);
      if (result.ok) {
        setReview(null);
        setForm(EMPTY_FORM);
        setPinNotice(null);
        setResetCount((n) => n + 1);
        toast.success('تم تأكيد طلب الكابتن بنجاح', {
          description: `تم إنشاء الطلب رقم ${result.value.reference} وإرساله إلى النظام.`,
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
    form, errors, set, normalizeOrderValue, areaOptions, selectedArea, resolution, areaError, pinError, pinNotice, selectArea, setPin,
    resetCount, review, submitting, submitError, openReview, closeReview, confirm,
  };
}
