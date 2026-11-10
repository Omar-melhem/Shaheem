import type { ReactNode } from 'react';
import { cn } from '@/shared/lib/cn';

/** Label + control + error/hint. With `htmlFor`, the message gets id `${htmlFor}-msg` for aria-describedby. */
export const fieldMessageId = (htmlFor: string) => htmlFor + '-msg';

export function Field({
  label,
  required,
  optional,
  hint,
  error,
  children,
  htmlFor,
  className,
}: {
  label: ReactNode;
  required?: boolean;
  optional?: boolean;
  hint?: ReactNode;
  error?: string | null;
  children: ReactNode;
  htmlFor?: string;
  className?: string;
}) {
  return (
    <div className={cn('space-y-1.5', className)}>
      <label htmlFor={htmlFor} className="flex items-center gap-2 text-sm font-bold text-ink">
        {label}
        {required && <span className="rounded-full bg-primary-50 px-2 py-0.5 text-[11px] font-bold text-primary">مطلوب</span>}
        {optional && <span className="rounded-full bg-cream-dark px-2 py-0.5 text-[11px] font-medium text-ink-muted">اختياري</span>}
      </label>
      {children}
      {error ? (
        <p id={htmlFor && fieldMessageId(htmlFor)} className="text-xs font-medium text-red-700" role="alert">
          {error}
        </p>
      ) : hint ? (
        <p id={htmlFor && fieldMessageId(htmlFor)} className="text-xs text-ink-muted">{hint}</p>
      ) : null}
    </div>
  );
}
