import {
  forwardRef,
  useEffect,
  useId,
  useRef,
  type ButtonHTMLAttributes,
  type InputHTMLAttributes,
  type ReactNode,
  type SelectHTMLAttributes,
  type TextareaHTMLAttributes,
} from 'react';
import { createPortal } from 'react-dom';
import { FlaskConical, Loader2, X } from 'lucide-react';
import { cn } from '@/shared/lib/cn';
import type { StatusTone } from '@/domain/orderStatus';

// ---------- Button ----------

type ButtonVariant = 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
type ButtonSize = 'sm' | 'md' | 'lg';

const buttonVariants: Record<ButtonVariant, string> = {
  primary: 'bg-primary text-white hover:bg-primary-600 active:bg-primary-700 shadow-sm',
  secondary: 'bg-secondary text-white hover:bg-secondary-600 active:bg-secondary-700 shadow-sm',
  outline: 'border border-cream-deep bg-white text-ink hover:bg-cream active:bg-cream-dark',
  ghost: 'text-ink-soft hover:bg-cream-dark active:bg-cream-deep',
  danger: 'bg-red-700 text-white hover:bg-red-800 shadow-sm',
};
const buttonSizes: Record<ButtonSize, string> = {
  sm: 'h-8 px-3 text-sm gap-1.5 rounded-lg',
  md: 'h-10 px-4 text-sm gap-2 rounded-xl',
  lg: 'h-12 px-6 text-base gap-2 rounded-xl',
};

export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  loading?: boolean;
  icon?: ReactNode;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { variant = 'primary', size = 'md', loading, icon, className, children, disabled, type = 'button', ...rest },
  ref,
) {
  return (
    <button
      ref={ref}
      type={type}
      disabled={disabled || loading}
      aria-busy={loading || undefined}
      className={cn(
        'inline-flex items-center justify-center whitespace-nowrap font-bold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300 focus-visible:ring-offset-1 disabled:cursor-not-allowed disabled:opacity-50',
        buttonVariants[variant],
        buttonSizes[size],
        className,
      )}
      {...rest}
    >
      {loading ? <Loader2 className="h-4 w-4 animate-spin" aria-hidden /> : icon}
      {children}
    </button>
  );
});

// ---------- Card ----------

export function Card({ className, children, ...rest }: { className?: string; children: ReactNode } & React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div className={cn('rounded-2xl border border-cream-deep/70 bg-white shadow-card', className)} {...rest}>
      {children}
    </div>
  );
}

export function CardHeader({ title, description, actions, icon }: { title: ReactNode; description?: ReactNode; actions?: ReactNode; icon?: ReactNode }) {
  return (
    <div className="flex flex-wrap items-start justify-between gap-3 border-b border-cream-dark px-5 py-4">
      <div className="flex min-w-0 items-start gap-3">
        {icon && <div className="mt-0.5 text-primary">{icon}</div>}
        <div className="min-w-0">
          <h2 className="text-base font-bold text-ink">{title}</h2>
          {description && <p className="mt-0.5 text-sm text-ink-muted">{description}</p>}
        </div>
      </div>
      {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
    </div>
  );
}

// ---------- Badge ----------

const badgeTones: Record<StatusTone, string> = {
  neutral: 'bg-gray-100 text-gray-700 ring-gray-200',
  sand: 'bg-sand-light/60 text-sand-dark ring-sand/40',
  warning: 'bg-amber-50 text-amber-800 ring-amber-200',
  primary: 'bg-primary-50 text-primary-700 ring-primary-200',
  info: 'bg-sky-50 text-sky-800 ring-sky-200',
  success: 'bg-secondary-50 text-secondary-600 ring-secondary-200',
  danger: 'bg-red-50 text-red-800 ring-red-200',
};

export function Badge({ tone = 'neutral', children, className, dot }: { tone?: StatusTone; children: ReactNode; className?: string; dot?: boolean }) {
  return (
    <span className={cn('inline-flex items-center gap-1.5 whitespace-nowrap rounded-full px-2.5 py-0.5 text-xs font-bold ring-1 ring-inset', badgeTones[tone], className)}>
      {dot && <span className="h-1.5 w-1.5 rounded-full bg-current" aria-hidden />}
      {children}
    </span>
  );
}

/** Marks simulated data/behaviour so it is never mistaken for production (SRS §19.3). */
export function SimTag({ children = 'محاكاة', className }: { children?: ReactNode; className?: string }) {
  return (
    <span className={cn('inline-flex items-center gap-1 rounded-md border border-dashed border-sand-dark/60 bg-sand-light/40 px-1.5 py-0.5 text-[11px] font-bold text-sand-dark', className)}>
      <FlaskConical className="h-3 w-3" aria-hidden />
      {children}
    </span>
  );
}

/** Notes an open Product Owner decision behind a demo behaviour. */
export function OpenDecision({ id, children }: { id: string; children: ReactNode }) {
  return (
    <p className="flex items-start gap-2 rounded-lg bg-cream px-3 py-2 text-xs text-ink-muted">
      <span className="mt-px shrink-0 rounded bg-white px-1.5 font-bold text-primary ring-1 ring-cream-deep" dir="ltr">
        {id}
      </span>
      <span>{children}</span>
    </p>
  );
}

// ---------- Form fields ----------

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
        {required && <span className="text-xs font-bold text-primary">مطلوب</span>}
        {optional && <span className="text-xs font-medium text-ink-muted">اختياري</span>}
      </label>
      {children}
      {error ? (
        <p className="text-xs font-medium text-red-700" role="alert">
          {error}
        </p>
      ) : hint ? (
        <p className="text-xs text-ink-muted">{hint}</p>
      ) : null}
    </div>
  );
}

const inputBase =
  'w-full rounded-xl border border-cream-deep bg-white px-3 text-sm text-ink placeholder:text-ink-muted/70 focus:border-primary-300 focus:outline-none focus:ring-2 focus:ring-primary-100 disabled:bg-cream disabled:text-ink-muted aria-[invalid=true]:border-red-400';

export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(function Input({ className, ...rest }, ref) {
  return <input ref={ref} className={cn(inputBase, 'h-10', className)} {...rest} />;
});

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaHTMLAttributes<HTMLTextAreaElement>>(function Textarea({ className, ...rest }, ref) {
  return <textarea ref={ref} className={cn(inputBase, 'min-h-[72px] py-2', className)} {...rest} />;
});

export const Select = forwardRef<HTMLSelectElement, SelectHTMLAttributes<HTMLSelectElement>>(function Select({ className, children, ...rest }, ref) {
  return (
    <select ref={ref} className={cn(inputBase, 'h-10 pe-8', className)} {...rest}>
      {children}
    </select>
  );
});

// ---------- Toggle ----------

export function Toggle({
  checked,
  onChange,
  label,
  description,
  disabled,
  tone = 'secondary',
}: {
  checked: boolean;
  onChange: (next: boolean) => void;
  label?: ReactNode;
  description?: ReactNode;
  disabled?: boolean;
  tone?: 'primary' | 'secondary';
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

// ---------- Dialog & Drawer ----------

function useEscape(open: boolean, onClose: () => void) {
  useEffect(() => {
    if (!open) return;
    const handler = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, [open, onClose]);
}

function useFocusOnOpen(open: boolean) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!open) return;
    const previous = document.activeElement as HTMLElement | null;
    const el = ref.current;
    const focusable = el?.querySelector<HTMLElement>('input, select, textarea, button:not([data-close])');
    (focusable ?? el)?.focus();
    return () => previous?.focus?.();
  }, [open]);
  return ref;
}

export function Dialog({
  open,
  onClose,
  title,
  description,
  children,
  footer,
  size = 'md',
}: {
  open: boolean;
  onClose: () => void;
  title: ReactNode;
  description?: ReactNode;
  children?: ReactNode;
  footer?: ReactNode;
  size?: 'sm' | 'md' | 'lg' | 'xl';
}) {
  useEscape(open, onClose);
  const ref = useFocusOnOpen(open);
  const titleId = useId();
  if (!open) return null;
  const widths = { sm: 'max-w-sm', md: 'max-w-lg', lg: 'max-w-2xl', xl: 'max-w-4xl' };
  return createPortal(
    <div className="fixed inset-0 z-[1000] flex items-end justify-center p-0 sm:items-center sm:p-4">
      <div className="absolute inset-0 bg-ink/50" onClick={onClose} aria-hidden />
      <div
        ref={ref}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        tabIndex={-1}
        className={cn('relative flex max-h-[92vh] w-full flex-col rounded-t-2xl bg-white shadow-pop focus:outline-none sm:rounded-2xl', widths[size])}
      >
        <div className="flex items-start justify-between gap-4 border-b border-cream-dark px-5 py-4">
          <div>
            <h2 id={titleId} className="text-lg font-bold text-ink">
              {title}
            </h2>
            {description && <p className="mt-0.5 text-sm text-ink-muted">{description}</p>}
          </div>
          <button data-close onClick={onClose} className="rounded-lg p-1.5 text-ink-muted hover:bg-cream" aria-label="إغلاق">
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="overflow-y-auto px-5 py-4">{children}</div>
        {footer && <div className="flex flex-wrap justify-end gap-2 border-t border-cream-dark px-5 py-3">{footer}</div>}
      </div>
    </div>,
    document.body,
  );
}

export function Drawer({
  open,
  onClose,
  title,
  subtitle,
  children,
  footer,
}: {
  open: boolean;
  onClose: () => void;
  title: ReactNode;
  subtitle?: ReactNode;
  children: ReactNode;
  footer?: ReactNode;
}) {
  useEscape(open, onClose);
  const ref = useFocusOnOpen(open);
  const titleId = useId();
  if (!open) return null;
  return createPortal(
    <div className="fixed inset-0 z-[900]">
      <div className="absolute inset-0 bg-ink/40" onClick={onClose} aria-hidden />
      <div
        ref={ref}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        tabIndex={-1}
        className="absolute inset-y-0 end-0 flex w-full max-w-xl flex-col bg-cream shadow-pop focus:outline-none"
      >
        <div className="flex items-start justify-between gap-4 border-b border-cream-deep bg-white px-5 py-4">
          <div className="min-w-0">
            <h2 id={titleId} className="truncate text-lg font-bold text-ink">
              {title}
            </h2>
            {subtitle && <div className="mt-1 text-sm text-ink-muted">{subtitle}</div>}
          </div>
          <button data-close onClick={onClose} className="rounded-lg p-1.5 text-ink-muted hover:bg-cream" aria-label="إغلاق">
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="flex-1 space-y-4 overflow-y-auto p-5">{children}</div>
        {footer && <div className="flex flex-wrap justify-end gap-2 border-t border-cream-deep bg-white px-5 py-3">{footer}</div>}
      </div>
    </div>,
    document.body,
  );
}

export function ConfirmDialog({
  open,
  onClose,
  onConfirm,
  title,
  description,
  confirmLabel = 'تأكيد',
  variant = 'primary',
  children,
}: {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: ReactNode;
  description?: ReactNode;
  confirmLabel?: string;
  variant?: ButtonVariant;
  children?: ReactNode;
}) {
  return (
    <Dialog
      open={open}
      onClose={onClose}
      title={title}
      size="sm"
      footer={
        <>
          <Button variant="outline" onClick={onClose}>
            تراجع
          </Button>
          <Button
            variant={variant}
            onClick={() => {
              onConfirm();
              onClose();
            }}
          >
            {confirmLabel}
          </Button>
        </>
      }
    >
      {description && <p className="text-sm text-ink-soft">{description}</p>}
      {children}
    </Dialog>
  );
}

// ---------- Misc ----------

export function EmptyState({ icon, title, description, action }: { icon?: ReactNode; title: ReactNode; description?: ReactNode; action?: ReactNode }) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 px-6 py-10 text-center">
      {icon && <div className="mb-1 rounded-2xl bg-cream p-3 text-sand-dark">{icon}</div>}
      <p className="font-bold text-ink">{title}</p>
      {description && <p className="max-w-sm text-sm text-ink-muted">{description}</p>}
      {action && <div className="mt-2">{action}</div>}
    </div>
  );
}

export function PageHeader({ title, description, actions }: { title: ReactNode; description?: ReactNode; actions?: ReactNode }) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 className="text-2xl font-extrabold text-ink">{title}</h1>
        {description && <p className="mt-1 max-w-3xl text-sm text-ink-muted">{description}</p>}
      </div>
      {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
    </div>
  );
}

export function StatCard({ label, value, icon, tone = 'neutral', hint }: { label: string; value: ReactNode; icon?: ReactNode; tone?: 'neutral' | 'primary' | 'secondary' | 'warning' | 'danger'; hint?: ReactNode }) {
  const tones = {
    neutral: 'bg-cream text-ink-soft',
    primary: 'bg-primary-50 text-primary',
    secondary: 'bg-secondary-50 text-secondary',
    warning: 'bg-amber-50 text-amber-700',
    danger: 'bg-red-50 text-red-700',
  };
  return (
    <Card className="flex items-center gap-4 p-4">
      {icon && <div className={cn('rounded-xl p-2.5', tones[tone])}>{icon}</div>}
      <div className="min-w-0">
        <p className="text-xs font-medium text-ink-muted">{label}</p>
        <p className="text-2xl font-extrabold leading-tight text-ink">{value}</p>
        {hint && <p className="text-[11px] text-ink-muted">{hint}</p>}
      </div>
    </Card>
  );
}

export function DetailRow({ label, children }: { label: ReactNode; children: ReactNode }) {
  return (
    <div className="flex items-start justify-between gap-4 py-2 text-sm">
      <dt className="shrink-0 text-ink-muted">{label}</dt>
      <dd className="min-w-0 text-end font-medium text-ink">{children}</dd>
    </div>
  );
}

export function Tabs<T extends string>({ value, onChange, items }: { value: T; onChange: (v: T) => void; items: Array<{ value: T; label: ReactNode; count?: number }> }) {
  return (
    <div role="tablist" className="inline-flex flex-wrap gap-1 rounded-xl bg-cream-dark p-1">
      {items.map((it) => (
        <button
          key={it.value}
          role="tab"
          aria-selected={value === it.value}
          onClick={() => onChange(it.value)}
          className={cn(
            'inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm font-bold transition-colors',
            value === it.value ? 'bg-white text-primary shadow-sm' : 'text-ink-muted hover:text-ink',
          )}
        >
          {it.label}
          {it.count !== undefined && (
            <span className={cn('rounded-full px-1.5 text-xs', value === it.value ? 'bg-primary-50' : 'bg-cream')}>{it.count}</span>
          )}
        </button>
      ))}
    </div>
  );
}
