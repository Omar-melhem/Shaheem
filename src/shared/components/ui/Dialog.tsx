import { useId, useRef, useState, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { X } from 'lucide-react';
import { cn } from '@/shared/lib/cn';
import { Button, type ButtonVariant } from './Button';
import { trapTabKey, useEscape, useFocusOnOpen } from './overlay';

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
        onKeyDown={trapTabKey}
        className={cn('relative flex min-h-0 max-h-[92dvh] w-full flex-col rounded-t-2xl bg-white shadow-pop focus:outline-none sm:rounded-2xl', widths[size])}
      >
        <div className="flex items-start justify-between gap-4 border-b border-cream-dark px-5 py-4">
          <div className="min-w-0 break-words">
            <h2 id={titleId} className="text-lg font-bold text-ink">
              {title}
            </h2>
            {description && <p className="mt-0.5 text-sm text-ink-muted">{description}</p>}
          </div>
          <button data-close onClick={onClose} className="shrink-0 rounded-lg p-3 text-ink-muted hover:bg-cream" aria-label="إغلاق">
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain px-4 py-4 sm:px-5">{children}</div>
        {footer && <div className="flex flex-wrap justify-end gap-2 border-t border-cream-dark px-5 py-3">{footer}</div>}
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
  cancelLabel = 'تراجع',
  variant = 'primary',
  children,
}: {
  open: boolean;
  onClose: () => void;
  onConfirm: () => void | boolean | null | Promise<void | boolean | null>;
  title: ReactNode;
  description?: ReactNode;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: ButtonVariant;
  children?: ReactNode;
}) {
  const lock = useRef(false);
  const [pending, setPending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const close = () => { if (!lock.current) { setError(null); onClose(); } };
  const confirm = async () => {
    if (lock.current) return;
    lock.current = true;
    setPending(true);
    setError(null);
    try {
      const success = await onConfirm();
      if (success !== false) { lock.current = false; onClose(); }
    } catch {
      setError('تعذّر تنفيذ العملية. حاول مرة أخرى.');
    } finally { lock.current = false; setPending(false); }
  };
  return (
    <Dialog
      open={open}
      onClose={close}
      title={title}
      size="sm"
      footer={
        <>
          <Button variant="outline" onClick={close} disabled={pending}>
            {cancelLabel}
          </Button>
          <Button
            variant={variant}
            loading={pending}
            onClick={confirm}
          >
            {confirmLabel}
          </Button>
        </>
      }
    >
      {description && <p className="text-sm text-ink-soft">{description}</p>}
      {children}
      {error && <p role="alert" className="mt-3 text-sm text-red-700">{error}</p>}
    </Dialog>
  );
}
