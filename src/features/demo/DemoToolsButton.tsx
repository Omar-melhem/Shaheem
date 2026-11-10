import { useState } from 'react';
import { FlaskConical } from 'lucide-react';
import { DemoControlsDrawer } from './DemoControlsDrawer';

/** Floating presenter-only entry point to the demo tools (SRS §19.8). */
export function DemoToolsButton() {
  const [open, setOpen] = useState(false);
  return (
    <>
      {/* Small screens: an icon-only tab on the left edge, so it never covers sticky actions or the Captain's bottom navigation. */}
      <button
        onClick={() => setOpen(true)}
        aria-label="أدوات العرض"
        title="أدوات العرض"
        className="fixed left-0 top-1/2 z-[800] inline-flex -translate-y-1/2 items-center gap-2 rounded-e-full border border-s-0 border-sand bg-cream py-2.5 pe-3 ps-2 text-sm font-bold text-sand-ink shadow-pop hover:bg-sand-light focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary-300 print:hidden lg:bottom-5 lg:left-5 lg:top-auto lg:translate-y-0 lg:rounded-full lg:border-s lg:px-4 lg:py-2"
      >
        <FlaskConical className="h-4 w-4" aria-hidden /> <span className="hidden lg:inline">أدوات العرض</span>
      </button>
      <DemoControlsDrawer open={open} onClose={() => setOpen(false)} />
    </>
  );
}
