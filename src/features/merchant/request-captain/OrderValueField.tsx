import { useId } from 'react';
import { Field, Input, fieldMessageId } from '@/shared/components/ui';

/**
 * Order value input. It only edits raw text, so forms such as "1." survive typing;
 * parsing, formatting and validation happen in the caller on blur and at review.
 */
export function OrderValueField({
  value,
  error,
  onChange,
  onBlur,
}: {
  value: string;
  error?: string;
  onChange: (raw: string) => void;
  onBlur: () => void;
}) {
  const id = useId();
  return (
    <Field label="قيمة الطلب" required htmlFor={id} error={error} hint="بالدينار الأردني، حتى ثلاث خانات عشرية." className="sm:max-w-[50%]">
      <Input
        id={id}
        type="text"
        inputMode="decimal"
        dir="ltr"
        autoComplete="off"
        className="rtl:text-right"
        placeholder="مثال: 12.500"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onBlur={onBlur}
        required
        aria-invalid={!!error}
        aria-describedby={fieldMessageId(id)}
      />
    </Field>
  );
}
