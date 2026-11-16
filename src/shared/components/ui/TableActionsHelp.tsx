import { useEffect, useId, useRef, useState, type ReactNode } from 'react';
import { Info, X } from 'lucide-react';

export interface ActionLegendItem {
  icon: ReactNode;
  label: string;
  /** One short sentence: what the action does or when it is unavailable. */
  description?: string;
}

export const TABLE_HELP_LABEL = 'شرح إجراءات الجدول';

/**
 * The one ⓘ help entry point above a table: a click-to-open popover listing only the icons this
 * table really uses. A supplement — every icon button keeps its own label and tooltip.
 * Closes on Escape (focus returns to the trigger), a tap outside, or its close button.
 * The panel is positioned against the nearest positioned ancestor (the table toolbar), so it can use the full toolbar width on phones.
 */
export function TableActionsHelp({ title, items }: { title: string; items: ActionLegendItem[] }) {
  const [open, setOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const panelRef = useRef<HTMLDivElement>(null);
  const panelId = useId();
  const titleId = useId();

  // Short screens: bring the whole panel into view instead of leaving its end below the fold.
  useEffect(() => {
    if (open) panelRef.current?.scrollIntoView?.({ block: 'nearest', behavior: 'smooth' });
  }, [open]);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape') return;
      setOpen(false);
      triggerRef.current?.focus();
    };
    const onDown = (e: PointerEvent) => !rootRef.current?.contains(e.target as Node) && setOpen(false);
    document.addEventListener('keydown', onKey);
    document.addEventListener('pointerdown', onDown);
    return () => {
      document.removeEventListener('keydown', onKey);
      document.removeEventListener('pointerdown', onDown);
    };
  }, [open]);

  return (
    <div ref={rootRef} className="inline-flex">
      <button
        ref={triggerRef}
        type="button"
        aria-label={TABLE_HELP_LABEL}
        aria-expanded={open}
        aria-controls={open ? panelId : undefined}
        onClick={() => setOpen((v) => !v)}
        className="inline-flex h-10 w-10 items-center justify-center rounded-lg text-ink-muted transition-colors hover:bg-cream-dark hover:text-secondary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300"
      >
        <Info className="h-5 w-5" aria-hidden />
      </button>
      {open && (
        <div
          ref={panelRef}
          id={panelId}
          role="dialog"
          aria-labelledby={titleId}
          className="absolute end-2 top-full z-50 mt-1 max-h-[60vh] w-[min(20rem,calc(100vw-2rem))] overflow-y-auto overscroll-contain rounded-xl border border-cream-deep bg-white p-3 text-start shadow-pop"
        >
          <div className="mb-2 flex items-center justify-between gap-2">
            <h3 id={titleId} className="text-sm font-bold text-ink">{title}</h3>
            <button type="button" aria-label="إغلاق الشرح" onClick={() => setOpen(false)} className="inline-flex h-8 w-8 items-center justify-center rounded-lg text-ink-muted hover:bg-cream">
              <X className="h-4 w-4" aria-hidden />
            </button>
          </div>
          <ul className="space-y-2">
            {items.map((a) => (
              <li key={a.label} className="flex items-start gap-2.5">
                <span className="mt-0.5 inline-flex h-7 w-7 shrink-0 items-center justify-center rounded-lg bg-cream text-ink-soft [&>svg]:h-4 [&>svg]:w-4" aria-hidden>{a.icon}</span>
                <span className="min-w-0">
                  <span className="block text-sm font-bold text-ink">{a.label}</span>
                  {a.description && <span className="block text-xs leading-relaxed text-ink-muted">{a.description}</span>}
                </span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}
