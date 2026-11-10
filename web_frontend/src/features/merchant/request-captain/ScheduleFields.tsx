import { useId } from 'react';
import { Field, Input } from '@/shared/components/ui';

/**
 * Requested Captain arrival at the Merchant, entered as Amman wall-clock date and time
 * (CR v1.4 §6.1). It is a pickup request, not a promised delivery time.
 */
export function ScheduleFields({
  date,
  time,
  minDate,
  error,
  onChange,
}: {
  date: string;
  time: string;
  minDate: string;
  error?: string;
  onChange: (patch: { date?: string; time?: string }) => void;
}) {
  const dateId = useId();
  const timeId = useId();
  return (
    <div className="space-y-2 rounded-xl border border-sand/60 bg-sand-light/20 p-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <Field label="تاريخ الاستلام" required htmlFor={dateId}>
          <Input id={dateId} type="date" min={minDate} value={date} onChange={(e) => onChange({ date: e.target.value })} aria-invalid={!!error} />
        </Field>
        <Field label="وقت وصول الكابتن إلى المتجر" required htmlFor={timeId}>
          <Input id={timeId} type="time" value={time} onChange={(e) => onChange({ time: e.target.value })} aria-invalid={!!error} />
        </Field>
      </div>
      {error ? (
        <p className="text-xs font-medium text-red-700" role="alert">{error}</p>
      ) : (
        <p className="text-xs text-ink-muted">بتوقيت عمّان. هذا موعد استلام الكابتن من المتجر، وليس موعداً مضموناً للتسليم إلى العميل. تنسّق إدارة شهم الكابتن يدوياً.</p>
      )}
    </div>
  );
}
