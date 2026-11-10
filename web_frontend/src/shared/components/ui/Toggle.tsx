import { useId, type ReactNode } from 'react';
import { cn } from '@/shared/lib/cn';

export function Toggle({
  checked,
  onChange,
  label,
  description,
  disabled,
  tone = 'secondary',
  'aria-label': ariaLabel,
}: {
  checked: boolean;
  onChange: (next: boolean) => void;
  label?: ReactNode;
  description?: ReactNode;
  disabled?: boolean;
  tone?: 'primary' | 'secondary';
  /** Accessible name when there is no visible label. */
  'aria-label'?: string;
}) {
  const id = useId();
  return (
    <div className="flex items-center justify-between gap-4">
      {(label || description) && (
        <div className="min-w-0">
          {label && (
            <label htmlFor={id} className="block text-sm font-bold text-ink">
              {label}
            </label>
          )}
          {description && <p className="text-xs text-ink-muted">{description}</p>}
        </div>
      )}
      <button
        id={id}
        type="button"
        role="switch"
        aria-checked={checked}
        aria-label={ariaLabel}
        disabled={disabled}
        onClick={() => onChange(!checked)}
        className={cn(
          'relative inline-flex h-7 w-12 shrink-0 items-center rounded-full transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300 disabled:opacity-50',
          checked ? (tone === 'primary' ? 'bg-primary' : 'bg-secondary') : 'bg-gray-300',
        )}
      >
        <span
          className={cn(
            'inline-block h-5 w-5 rounded-full bg-white shadow transition-transform',
            checked ? '-translate-x-6' : '-translate-x-1',
          )}
        />
      </button>
    </div>
  );
}
