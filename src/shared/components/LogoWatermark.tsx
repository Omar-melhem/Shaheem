import { cn } from '@/shared/lib/cn';
import { LOGO_SRC } from './Logo';

/**
 * Decorative brand texture: the official logo rendered monochrome (CSS grayscale —
 * the asset itself is untouched) at ~2.5% on the wrapper — a barely-there texture so the
 * keffiyeh figure never competes with the real logo (owner review 2026-11-21).
 *
 * Opacity sits on the wrapper, not the image, so the one-time fade-in on the
 * image can't override it. Hidden from assistive tech and pointer input; place inside a `relative
 * overflow-hidden` parent with content in a `relative` layer above it.
 */
export function LogoWatermark({ className }: { className?: string }) {
  return (
    <div className="pointer-events-none absolute inset-0 select-none overflow-hidden opacity-[0.025]" aria-hidden="true">
      <img src={LOGO_SRC} alt="" draggable={false} className={cn('absolute max-w-none grayscale motion-safe:animate-fade', className)} />
    </div>
  );
}
