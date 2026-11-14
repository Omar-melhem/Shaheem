import { useId, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { X } from 'lucide-react';
import { trapTabKey, useEscape, useFocusOnOpen } from './overlay';

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
        onKeyDown={trapTabKey}
        className="absolute inset-y-0 end-0 flex w-full max-w-xl flex-col bg-cream shadow-pop focus:outline-none"
      >
        <div className="flex items-start justify-between gap-4 border-b border-cream-deep bg-white px-5 py-4">
          <div className="min-w-0">
            <h2 id={titleId} className="truncate text-lg font-bold text-ink">
              {title}
            </h2>
            {subtitle && <div className="mt-1 text-sm text-ink-muted">{subtitle}</div>}
          </div>
          <button data-close onClick={onClose} className="shrink-0 rounded-lg p-3 text-ink-muted hover:bg-cream" aria-label="إغلاق">
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="min-h-0 flex-1 space-y-4 overflow-y-auto overscroll-contain p-4 sm:p-5">{children}</div>
        {footer && <div className="flex flex-wrap justify-end gap-2 border-t border-cream-deep bg-white px-5 py-3">{footer}</div>}
      </div>
    </div>,
    document.body,
  );
}
