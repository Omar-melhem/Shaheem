import { cloneElement, isValidElement, useId, type ReactElement, type ReactNode } from 'react';
import { cn } from '@/shared/lib/cn';

/**
 * Label + control + error/hint. With `htmlFor`, the message gets id `${htmlFor}-msg` for aria-describedby.
 * Without `htmlFor`, a single control child (Input, Select, PhoneField…) is linked automatically, so the
 * label is always announced with its field.
 */
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
  const autoId = useId();
  const linkable = !htmlFor && isLinkableControl(children);
  const controlId = htmlFor ?? (linkable ? autoId : undefined);
  const control = linkable
    ? cloneElement(children as ReactElement<{ id?: string; 'aria-describedby'?: string }>, {
        id: autoId,
        'aria-describedby': error || hint ? fieldMessageId(autoId) : undefined,
      })
    : children;
  return (
    <div className={cn('space-y-1.5', className)}>
      <label htmlFor={controlId} className="flex items-center gap-2 text-sm font-bold text-ink">
        {label}
        {required && <span className="rounded-full bg-primary-50 px-2 py-0.5 text-[11px] font-bold text-primary">مطلوب</span>}
        {optional && <span className="rounded-full bg-cream px-2 py-0.5 text-[11px] font-medium text-ink-soft">اختياري</span>}
      </label>
      {control}
      {error ? (
        <p id={controlId && fieldMessageId(controlId)} className="text-xs font-medium text-red-700" role="alert">
          {error}
        </p>
      ) : hint ? (
        <p id={controlId && fieldMessageId(controlId)} className="text-xs text-ink-muted">{hint}</p>
      ) : null}
    </div>
  );
}

/** A single form control element without its own id (plain wrappers like <div> are left alone). */
function isLinkableControl(children: ReactNode): boolean {
  if (!isValidElement(children)) return false;
  const props = children.props as { id?: string };
  if (props.id) return false;
  return typeof children.type !== 'string' || ['input', 'select', 'textarea'].includes(children.type);
}
