import { useState } from 'react';
import { FlaskConical } from 'lucide-react';
import { cn } from '@/shared/lib/cn';
import { DemoControlsDrawer } from './DemoControlsDrawer';

const VARIANT_CLASS = {
  /** A compact pill in the Admin / Merchant top bar: never floats over page content. */
  header:
    'h-9 rounded-full border border-sand bg-cream px-2.5 text-xs text-sand-ink hover:bg-sand-light sm:px-3',
  /** A full-width row inside another panel (the login «أدوات وحسابات العرض» panel). */
  inline: 'h-10 w-full justify-center rounded-xl border border-sand bg-white px-3 text-sm text-sand-ink hover:bg-sand-light',
  /** Captain phone mock-up only: sits outside the mock-up on the page background. */
  floating:
    'fixed bottom-5 left-5 z-[800] rounded-full border border-sand bg-cream px-4 py-2 text-sm text-sand-ink shadow-pop hover:bg-sand-light',
} as const;

/** Presenter-only entry point to the demo tools (SRS §19.8). Placed by each layout, never globally. */
export function DemoToolsButton({ variant = 'header' }: { variant?: keyof typeof VARIANT_CLASS }) {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button
        type="button"
        onClick={() => setOpen(true)}
        aria-label="أدوات العرض"
        title="أدوات العرض"
        className={cn(
          'inline-flex shrink-0 items-center gap-1.5 font-bold focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-secondary-300 print:hidden',
          VARIANT_CLASS[variant],
        )}
      >
        <FlaskConical className="h-4 w-4" aria-hidden />
        <span className={variant === 'header' ? 'hidden sm:inline' : undefined}>أدوات العرض</span>
      </button>
      <DemoControlsDrawer open={open} onClose={() => setOpen(false)} />
    </>
  );
}
