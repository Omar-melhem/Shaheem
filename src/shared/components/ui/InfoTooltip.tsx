import { useEffect, useId, useRef, useState } from 'react';
import { Info } from 'lucide-react';
import { cn } from '@/shared/lib/cn';

/**
 * Small information icon with a tooltip. Opens on hover, keyboard focus and
 * tap/click (touch has no hover); Escape or a tap outside closes it.
 * The text is linked with aria-describedby so screen readers announce it.
 */
export function InfoTooltip({ text, label = 'معلومة', className }: { text: string; label?: string; className?: string }) {
  const [open, setOpen] = useState(false);
  const id = useId();
  const ref = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && setOpen(false);
    const onDown = (e: PointerEvent) => !ref.current?.contains(e.target as Node) && setOpen(false);
    document.addEventListener('keydown', onKey);
    document.addEventListener('pointerdown', onDown);
    return () => {
      document.removeEventListener('keydown', onKey);
      document.removeEventListener('pointerdown', onDown);
    };
  }, [open]);

  return (
    <span ref={ref} className={cn('relative inline-flex', className)} onMouseEnter={() => setOpen(true)} onMouseLeave={() => setOpen(false)}>
      <button
        type="button"
        aria-label={label}
        aria-describedby={id}
        aria-expanded={open}
        onClick={() => setOpen(true) /* not a toggle: focus/hover already opened it on a real click or tap */}
        onFocus={() => setOpen(true)}
        onBlur={() => setOpen(false)}
        className="inline-flex h-6 w-6 items-center justify-center rounded-full text-ink-muted transition-colors hover:text-secondary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300"
      >
        <Info className="h-4 w-4" aria-hidden />
      </button>
      <span
        id={id}
        role="tooltip"
        className={cn(
          'absolute start-1/2 top-full z-50 mt-2 w-64 rounded-xl bg-ink px-3 py-2 text-xs leading-relaxed text-white shadow-pop transition-opacity duration-150 rtl:translate-x-1/2 ltr:-translate-x-1/2',
          open ? 'opacity-100' : 'pointer-events-none opacity-0',
        )}
      >
        {text}
      </span>
    </span>
  );
}
