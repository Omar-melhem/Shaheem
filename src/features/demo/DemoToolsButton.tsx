import { useState } from 'react';
import { FlaskConical } from 'lucide-react';
import { DemoControlsDrawer } from './DemoControlsDrawer';

/** Floating presenter-only entry point to the demo tools (SRS §19.8). */
export function DemoToolsButton() {
  const [open, setOpen] = useState(false);
  return (
    <>
      <button
        onClick={() => setOpen(true)}
        className="fixed bottom-5 left-5 z-[800] print:hidden inline-flex items-center gap-2 rounded-full border border-sand bg-cream px-4 py-2 text-sm font-bold text-sand-dark shadow-pop hover:bg-sand-light"
      >
        <FlaskConical className="h-4 w-4" aria-hidden /> أدوات العرض
      </button>
      <DemoControlsDrawer open={open} onClose={() => setOpen(false)} />
    </>
  );
}
