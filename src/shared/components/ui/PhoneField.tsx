import { forwardRef, type InputHTMLAttributes } from 'react';
import { PHONE_DIGITS, normalizePhone } from '@/domain/phone';
import { cn } from '@/shared/lib/cn';
import { Input } from './Inputs';

type Props = Omit<InputHTMLAttributes<HTMLInputElement>, 'type' | 'value' | 'onChange'> & {
  value: string;
  onChange: (digits: string) => void;
};

/**
 * Telephone input (FU-1.2 §1.3): keeps digits only (Arabic-Indic digits are
 * converted, spaces and separators dropped), at most 10, leading zero preserved.
 * The value stays a string — never a number. Pair with `isValidPhone` for the error.
 */
export const PhoneField = forwardRef<HTMLInputElement, Props>(function PhoneField({ value, onChange, className, ...rest }, ref) {
  return (
    <Input
      ref={ref}
      type="tel"
      inputMode="numeric"
      autoComplete="off"
      dir="ltr"
      maxLength={PHONE_DIGITS + 6 /* room to paste "079 123 4567" before normalising */}
      placeholder="07XXXXXXXX"
      className={cn('rtl:text-right', className)}
      value={value}
      onChange={(e) => onChange(normalizePhone(e.target.value).slice(0, PHONE_DIGITS))}
      {...rest}
    />
  );
});

/** Hint shown under phone fields so the normalisation rule is visible. */
export const PHONE_HINT = 'عشرة أرقام، مثل 07XXXXXXXX — تُحذف المسافات والرموز تلقائياً.';
